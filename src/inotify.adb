-- Copyright (c) 2019 Bartek thindil Jasicki <thindil@laeran.pl>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings; use Interfaces.C.Strings;
with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with ada.text_io;

package body Inotify is

   Instance: File_Descriptor;

   type Watch_Data is record
      Id: int;
      Path: Unbounded_String;
   end record;

   package Int_Container is new Vectors(Positive, Watch_Data);

   Watches: Int_Container.Vector;

   type Mask_Array is array(Positive range <>) of Inotify_Events;

   function inotify_init return int with
      Import => True,
      Convention => C,
      External_Name => "inotify_init";

   function inotify_add_watch
     (fd: int; pathname: chars_ptr; mask: int) return int with
      Import => True,
      Convention => C,
      External_Name => "inotify_add_watch";

   function inotify_rm_watch(fd, wd: int) return int with
      Import => True,
      Convention => C,
      External_Name => "inotify_rm_watch";

   procedure InotifyInit is
   begin
      Instance := File_Descriptor(inotify_init);
   end InotifyInit;

   procedure InotifyClose is
   begin
      Close(Instance);
   end InotifyClose;

   function CreateMask(Events: Mask_Array) return int is
      type Unsigned_Integer is mod 2**Integer'Size;
      Mask: Unsigned_Integer :=
        Unsigned_Integer(Inotify_Events'Enum_Rep(Events(1)));
   begin
      for I in 2 .. Events'Last loop
         Mask := Mask or Unsigned_Integer(Inotify_Events'Enum_Rep(Events(I)));
      end loop;
      return int(Mask);
   end CreateMask;

   procedure AddWatch(Path: String) is
      Watch: int;
      Mask: constant int :=
        CreateMask((Metadata, Closed_Write, Moved_From, Moved_To, Deleted));
   begin
      Watch := inotify_add_watch(int(Instance), New_String(Path), Mask);
      if Watch > 0 then
         Watches.Append((Watch, To_Unbounded_String(Path)));
      end if;
   end AddWatch;

   procedure AddWatches(Path: String) is
      Directory: Dir_Type;
      Last: Natural;
      FileName: String(1 .. 1024);
   begin
      AddWatch(Path);
      Open(Directory, Path);
      loop
         Read(Directory, FileName, Last);
         exit when Last = 0;
         if FileName(1 .. Last) in "." | ".." then
            goto End_Of_Loop;
         end if;
         if Is_Directory(Path & Directory_Separator & FileName(1 .. Last))
           and then Is_Read_Accessible_File
             (Path & Directory_Separator & FileName(1 .. Last)) then
            AddWatch(Path & "/" & FileName(1 .. Last));
         end if;
         <<End_Of_Loop>>
      end loop;
      Close(Directory);
   end AddWatches;

   procedure RemoveWatches is
   begin
      for Watch of Watches loop
         if inotify_rm_watch(int(Instance), Watch.Id) = -1 then
            null;
         end if;
      end loop;
      Watches.Clear;
   end RemoveWatches;

   procedure InotifyRead is
      Buffer: array(1 .. 4096) of Character;
      Length, NameLength: Integer;
      Path, Target: Unbounded_String;
      Event: Inotify_Events;
   begin
      loop
         Length := Read(Instance, Buffer'Address, 4096);
         if Length = -1 then
            exit;
         end if;
         for Watch of Watches loop
            if int(Character'Pos(Buffer(1))) = Watch.Id then
               Path := Watch.Path;
               NameLength := Character'Pos(Buffer(13)) + 17;
               Target := Null_Unbounded_String;
               for I in 17 .. NameLength loop
                  exit when Character'Pos(Buffer(I)) = 0;
                  Append(Target, Buffer(I));
               end loop;
               exit;
            end if;
         end loop;
         if Character'Pos(Buffer(5)) > 0 then
            Event := Inotify_Events'Enum_val(Character'Pos(Buffer(5)));
         else
            Event := Inotify_Events'Enum_val(Character'Pos(Buffer(6)));
         end if;
         EventsList.Append((Event, Target, Path));
         Ada.Text_IO.Put_Line("Event:" & Inotify_Events'Image(Event) & " Target: " & To_String(Target) & " Path: " & To_String(Path));
      end loop;
   end InotifyRead;

end Inotify;

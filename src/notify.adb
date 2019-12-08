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

with Ada.Containers.Vectors; use Ada.Containers;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings; use Interfaces.C.Strings;
with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with Ada.Text_IO;

package body Notify is

   Instance: File_Descriptor;

   package Int_Container is new Vectors(Positive, int);

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
      Mask: Unsigned_Integer := Unsigned_Integer(Inotify_Events'Enum_Rep(Events(1)));
   begin
      for I in 2 .. Events'Last loop
         Mask := Mask or Unsigned_Integer(Inotify_Events'Enum_Rep(Events(I)));
      end loop;
      return int(Mask);
   end CreateMask;

   procedure AddWatch(Path: String) is
      Watch: int;
      Directory: Dir_Type;
      Last: Natural;
      FileName: String(1 .. 1024);
      Mask: constant int :=
        CreateMask((Metadata, Closed_Write, Moved_From, Moved_To, Deleted));
   begin
      Watch := inotify_add_watch(int(Instance), New_String(Path), Mask);
      if Watch > 0 then
         Watches.Append(Watch);
      end if;
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
            Watch :=
              inotify_add_watch
                (int(Instance), New_String(Path & "/" & FileName(1 .. Last)),
                 Mask);
            if Watch > 0 then
               Watches.Append(Watch);
            end if;
         end if;
         <<End_Of_Loop>>
      end loop;
      Close(Directory);
      Ada.Text_IO.Put_Line(Integer'Image(Integer(Watches.Length)));
   end AddWatch;

   procedure RemoveWatches is
   begin
      for Watch of Watches loop
         if inotify_rm_watch(int(Instance), Watch) = -1 then
            null;
         end if;
      end loop;
      Watches.Clear;
   end RemoveWatches;

end Notify;

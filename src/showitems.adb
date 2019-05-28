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

with Ada.Calendar.Formatting;
with Ada.Calendar.Time_Zones;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;
with Ada.Command_Line; use Ada.Command_Line;
with Ada.Containers; use Ada.Containers;
with Ada.Directories; use Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with GNAT.Expect; use GNAT.Expect;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with GNAT.String_Split; use GNAT.String_Split;
with Gtk.Button; use Gtk.Button;
with Gtk.Image; use Gtk.Image;
with Gtk.Label; use Gtk.Label;
with Gtk.List_Store; use Gtk.List_Store;
with Gtk.Radio_Tool_Button; use Gtk.Radio_Tool_Button;
with Gtk.Stack; use Gtk.Stack;
with Gtk.Text_Buffer; use Gtk.Text_Buffer;
with Gtk.Text_Iter; use Gtk.Text_Iter;
with Gtk.Text_View; use Gtk.Text_View;
with Gtk.Tree_Model; use Gtk.Tree_Model;
with Gtk.Tree_Selection; use Gtk.Tree_Selection;
with Gtk.Tree_View; use Gtk.Tree_View;
with Gtk.Toggle_Button; use Gtk.Toggle_Button;
with Gtk.Widget; use Gtk.Widget;
with LoadData; use LoadData;
with MainWindow; use MainWindow;
with Messages; use Messages;
with Utils; use Utils;

package body ShowItems is

   -- ****iv* ShowItems/DesktopFile
   -- FUNCTION
   -- Name of .desktop file or name of application associated with selected
   -- file.
   -- SOURCE
   DesktopFile: Unbounded_String;
   -- ****

   -- ****if* ShowItems/FindFileName
   -- FUNCTION
   -- Find name of associated program with selected file. If found, replace
   -- .desktop file name with name of application.
   -- PARAMETERS
   -- Model - Gtk_Tree_Model with content of currently selected directory
   -- Path  - Gtk_Tree_Path to selected element in Model
   -- Iter  - Gtk_Tree_Iter to selected element in Model
   -- SOURCE
   function FindFileName(Model: Gtk_Tree_Model; Path: Gtk_Tree_Path;
      Iter: Gtk_Tree_Iter) return Boolean is
      pragma Unreferenced(Path);
      -- ****
   begin
      if Get_String(Model, Iter, 1) = To_String(DesktopFile) then
         DesktopFile := To_Unbounded_String(Get_String(Model, Iter, 0));
         return True;
      end if;
      return False;
   end FindFileName;

   -- ****if* ShowItems/GetSelectedItems
   -- FUNCTION
   -- Add selected file or directory to SelectedItems list.
   -- PARAMETERS
   -- Model - Gtk_Tree_Model with content of currently selected directory
   -- Path  - Gtk_Tree_Path to selected element in Model
   -- Iter  - Gtk_Tree_Iter to selected element in Model
   -- SOURCE
   procedure GetSelectedItems(Model: Gtk_Tree_Model; Path: Gtk_Tree_Path;
      Iter: Gtk_Tree_Iter) is
      pragma Unreferenced(Path);
      -- ****
   begin
      if CurrentDirectory = To_Unbounded_String("/") then
         CurrentDirectory := Null_Unbounded_String;
      end if;
      SelectedItems.Append
        (CurrentDirectory &
         To_Unbounded_String("/" & Get_String(Model, Iter, 0)));
   end GetSelectedItems;

   procedure ShowItemInfo(Object: access Gtkada_Builder_Record'Class) is
      Amount: Natural := 0;
      Directory: Dir_Type;
      Last: Natural;
      FileName: String(1 .. 1024);
      SelectedPath: constant String := Full_Name(To_String(CurrentSelected));
      ObjectsNames: constant array(Positive range <>) of Unbounded_String :=
        (To_Unbounded_String("lblfiletype"),
         To_Unbounded_String("lblfiletype2"),
         To_Unbounded_String("btnprogram"), To_Unbounded_String("lblprogram2"),
         To_Unbounded_String("cbtnownerexecute"),
         To_Unbounded_String("cbtngroupexecute"),
         To_Unbounded_String("cbtnothersexecute"));
   begin
      Set_Label(Gtk_Label(Get_Object(Object, "lblname")), SelectedPath);
      Set_Label(Gtk_Label(Get_Object(Object, "lblsize2")), "Size:");
      if Is_Symbolic_Link(To_String(CurrentSelected)) then
         Set_Label(Gtk_Label(Get_Object(Object, "lblname2")), "Links to:");
      else
         Set_Label(Gtk_Label(Get_Object(Object, "lblname2")), "Full path:");
      end if;
      for Name of ObjectsNames loop
         Hide(Gtk_Widget(Get_Object(Object, To_String(Name))));
      end loop;
      if Is_Regular_File(SelectedPath) then
         for Name of ObjectsNames loop
            Show_All(Gtk_Widget(Get_Object(Object, To_String(Name))));
         end loop;
         Set_Label
           (Gtk_Label(Get_Object(Object, "lblsize")),
            CountFileSize(Size(SelectedPath)));
         Set_Label
           (Gtk_Label(Get_Object(Object, "lbllastmodified")),
            Ada.Calendar.Formatting.Image
              (Modification_Time(SelectedPath), False,
               Ada.Calendar.Time_Zones.UTC_Time_Offset));
         Set_Label
           (Gtk_Label(Get_Object(Object, "lblfiletype")),
            GetMimeType(SelectedPath));
         if not CanBeOpened(GetMimeType(SelectedPath)) then
            Set_Label(Gtk_Button(Get_Object(Object, "btnprogram")), "none");
         else
            declare
               ProcessDesc: Process_Descriptor;
               Result: Expect_Match;
            begin
               Non_Blocking_Spawn
                 (ProcessDesc,
                  Containing_Directory(Command_Name) & "/xdg-mime",
                  Argument_String_To_List
                    ("query default " & GetMimeType(SelectedPath)).all);
               Expect(ProcessDesc, Result, Regexp => ".+", Timeout => 1_000);
               if Result = 1 then
                  DesktopFile :=
                    To_Unbounded_String(Expect_Out_Match(ProcessDesc));
                  Foreach
                    (Gtk_List_Store(Get_Object(Object, "applicationsstore")),
                     FindFileName'Access);
                  if Index(DesktopFile, ".desktop") = 0 then
                     Set_Label
                       (Gtk_Button(Get_Object(Object, "btnprogram")),
                        To_String(DesktopFile));
                  else
                     Set_Label
                       (Gtk_Label(Get_Object(Object, "lblprogram")),
                        To_String(DesktopFile) & " (not installed)");
                  end if;
               end if;
               Close(ProcessDesc);
            end;
         end if;
      elsif Is_Directory(SelectedPath) then
         Set_Label(Gtk_Label(Get_Object(Object, "lblsize2")), "Elements:");
         if Is_Read_Accessible_File(SelectedPath) then
            Open(Directory, SelectedPath);
            loop
               Read(Directory, FileName, Last);
               exit when Last = 0;
               Amount := Amount + 1;
            end loop;
            Close(Directory);
            Set_Label
              (Gtk_Label(Get_Object(Object, "lblsize")),
               Natural'Image(Amount - 2));
         else
            Set_Label(Gtk_Label(Get_Object(Object, "lblsize")), "Unknown");
         end if;
         Set_Label
           (Gtk_Label(Get_Object(Object, "lbllastmodified")),
            Ada.Calendar.Formatting.Image(Modification_Time(SelectedPath)));
      else
         if SelectedPath = "" then
            Set_Label(Gtk_Label(Get_Object(Object, "lblname")), "Unknown");
         end if;
         Set_Label(Gtk_Label(Get_Object(Object, "lblsize")), "Unknown");
         for I in 5 .. 7 loop
            Show_All
              (Gtk_Widget(Get_Object(Object, To_String(ObjectsNames(I)))));
         end loop;
      end if;
      declare
         ProcessDesc: Process_Descriptor;
         Result: Expect_Match;
         FileStats: Unbounded_String;
         Tokens: Slice_Set;
         ButtonNames: constant array(3 .. 11) of Unbounded_String :=
           (To_Unbounded_String("cbtnownerread"),
            To_Unbounded_String("cbtnownerwrite"),
            To_Unbounded_String("cbtnownerexecute"),
            To_Unbounded_String("cbtngroupread"),
            To_Unbounded_String("cbtngroupwrite"),
            To_Unbounded_String("cbtngroupexecute"),
            To_Unbounded_String("cbtnothersread"),
            To_Unbounded_String("cbtnotherswrite"),
            To_Unbounded_String("cbtnothersexecute"));
      begin
         Non_Blocking_Spawn
           (ProcessDesc, "stat",
            Argument_String_To_List
              ("-c""%A %U %G"" " & To_String(CurrentSelected)).all);
         Expect(ProcessDesc, Result, Regexp => ".+", Timeout => 1_000);
         if Result = 1 then
            FileStats := To_Unbounded_String(Expect_Out_Match(ProcessDesc));
            Create(Tokens, To_String(FileStats), " ");
            Set_Label
              (Gtk_Label(Get_Object(Object, "lblowner")), Slice(Tokens, 2));
            Set_Label
              (Gtk_Label(Get_Object(Object, "lblgroup")),
               Slice(Tokens, 3)
                 (Slice(Tokens, 3)'First .. Slice(Tokens, 3)'Last - 1));
            for I in ButtonNames'Range loop
               if Slice(Tokens, 1)(I) = '-' then
                  Set_Active
                    (Gtk_Toggle_Button
                       (Get_Object(Object, To_String(ButtonNames(I)))),
                     False);
               else
                  Set_Active
                    (Gtk_Toggle_Button
                       (Get_Object(Object, To_String(ButtonNames(I)))),
                     True);
               end if;
            end loop;
         end if;
         Close(ProcessDesc);
      exception
         when Process_Died =>
            return;
      end;
      Set_Visible_Child_Name
        (Gtk_Stack(Get_Object(Builder, "infostack")), "info");
   end ShowItemInfo;

   procedure PreviewItem(Object: access Gtkada_Builder_Record'Class) is
   begin
      if Setting then
         return;
      end if;
      if Is_Directory(To_String(CurrentSelected)) then
         Show_All(Gtk_Widget(Get_Object(Object, "scrolllist")));
         Hide(Gtk_Widget(Get_Object(Object, "scrolltext")));
         Hide(Gtk_Widget(Get_Object(Object, "scrollimage")));
         Hide(Gtk_Widget(Get_Object(Object, "btnrun")));
         LoadDirectory(To_String(CurrentSelected), "fileslist1");
      else
         Show_All(Gtk_Widget(Get_Object(Object, "scrolltext")));
         Hide(Gtk_Widget(Get_Object(Object, "scrolllist")));
         Hide(Gtk_Widget(Get_Object(Object, "scrollimage")));
         declare
            MimeType: constant String :=
              GetMimeType(To_String(CurrentSelected));
            Buffer: constant Gtk_Text_Buffer :=
              Get_Buffer(Gtk_Text_View(Get_Object(Object, "filetextview")));
            Iter: Gtk_Text_Iter;
            File: File_Type;
         begin
            Set_Text(Buffer, "");
            Get_Start_Iter(Buffer, Iter);
            if not Is_Executable_File(To_String(CurrentSelected)) then
               Hide(Gtk_Widget(Get_Object(Builder, "btnrun")));
            end if;
            if MimeType(1 .. 4) = "text" then
               Open(File, In_File, To_String(CurrentSelected));
               while not End_Of_File(File) loop
                  Insert(Buffer, Iter, Get_Line(File) & LF);
               end loop;
               Close(File);
            elsif MimeType(1 .. 5) = "image" then
               Hide(Gtk_Widget(Get_Object(Object, "scrolltext")));
               Set
                 (Gtk_Image(Get_Object(Object, "imgpreview")),
                  To_String(CurrentSelected));
               Show_All(Gtk_Widget(Get_Object(Object, "scrollimage")));
            else
               Hide(Gtk_Widget(Get_Object(Object, "btnpreview")));
               if not CanBeOpened(MimeType) then
                  Hide(Gtk_Widget(Get_Object(Object, "btnopen")));
               end if;
               Setting := True;
               Set_Active
                 (Gtk_Radio_Tool_Button(Get_Object(Object, "btnfileinfo")),
                  True);
               Setting := False;
               return;
            end if;
         end;
      end if;
      Set_Visible_Child_Name
        (Gtk_Stack(Get_Object(Builder, "infostack")), "preview");
   end PreviewItem;

   procedure ShowItem(Object: access Gtkada_Builder_Record'Class) is
   begin
      if Setting then
         return;
      end if;
      SelectedItems.Clear;
      Selected_Foreach
        (Gtk.Tree_View.Get_Selection
           (Gtk_Tree_View(Get_Object(Object, "treefiles"))),
         GetSelectedItems'Access);
      if SelectedItems.Length /= 1 then
         Hide(Gtk_Widget(Get_Object(Object, "scrolltext")));
         Hide(Gtk_Widget(Get_Object(Object, "scrolllist")));
         Hide(Gtk_Widget(Get_Object(Object, "itemtoolbar")));
         return;
      end if;
      if CurrentSelected = SelectedItems(1) then
         return;
      end if;
      CurrentSelected := SelectedItems(1);
      Show_All(Gtk_Widget(Get_Object(Object, "itemtoolbar")));
      Set_Active
        (Gtk_Radio_Tool_Button(Get_Object(Object, "btnpreview")), True);
      PreviewItem(Object);
   end ShowItem;

   procedure SetAssociated(Object: access Gtkada_Builder_Record'Class) is
      Pid: GNAT.OS_Lib.Process_Id;
      ProgramIter: Gtk_Tree_Iter;
      ProgramModel: Gtk_Tree_Model;
   begin
      Get_Selected
        (Gtk.Tree_View.Get_Selection
           (Gtk_Tree_View(Get_Object(Object, "treeprograms"))),
         ProgramModel, ProgramIter);
      if ProgramIter /= Null_Iter then
         Pid :=
           Non_Blocking_Spawn
             (Containing_Directory(Command_Name) & "/xdg-mime",
              Argument_String_To_List
                ("default " & Get_String(ProgramModel, ProgramIter, 1) & " " &
                 GetMimeType(To_String(CurrentSelected))).all);
         if Pid = GNAT.Os_Lib.Invalid_Pid then
            ShowMessage("I can't set new associated file.");
         else
            Set_Label
              (Gtk_Button(Get_Object(Object, "btnprogram")),
               Get_String(ProgramModel, ProgramIter, 0));
         end if;
         Set_Active
           (Gtk_Toggle_Button(Get_Object(Object, "btnprogram")), False);
      end if;
   end SetAssociated;

end ShowItems;
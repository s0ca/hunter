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

with Ada.Environment_Variables; use Ada.Environment_Variables;
with Ada.Directories; use Ada.Directories;
with Gtk.Main;
with Gtk.Widget; use Gtk.Widget;
with Gtk.Paned; use Gtk.Paned;
with Gtk.List_Store; use Gtk.List_Store;
with Gtk.Tree_Model; use Gtk.Tree_Model;
with Gtk.Enums; use Gtk.Enums;
with Glib; use Glib;

package body MainWindow is

   Builder: Gtkada_Builder;

   procedure Quit(Object: access Gtkada_Builder_Record'Class) is
   begin
      Unref(Object);
      Gtk.Main.Main_Quit;
   end Quit;

   procedure ResizePaned(Object: access Gtkada_Builder_Record'Class) is
   begin
      Set_Position
        (Gtk_Paned(Get_Object(Object, "paned1")),
         Gint
           (Float
              (Get_Allocated_Width
                 (Gtk_Widget(Get_Object(Object, "mainwindow")))) *
            0.4));
   end ResizePaned;

   procedure LoadDirectory(Name: String) is
      FilesList: constant Gtk_List_Store :=
        Gtk_List_Store(Get_Object(Builder, "fileslist"));
      FileIter: Gtk_Tree_Iter;
      Files: Search_Type;
      FoundFile: Directory_Entry_Type;
   begin
      FilesList.Clear;
      Start_Search(Files, Name, "");
      while More_Entries(Files) loop
         Get_Next_Entry(Files, FoundFile);
         Append(FilesList, FileIter);
         if Kind(FoundFile) = Directory then
            if Simple_Name(FoundFile)(1) = '.' then
               Set(FilesList, FileIter, 0, "   " & Simple_Name(FoundFile));
            else
               Set(FilesList, FileIter, 0, "  " & Simple_Name(FoundFile));
            end if;
         else
            if Simple_Name(FoundFile)(1) = '.' then
               Set(FilesList, FileIter, 0, " " & Simple_Name(FoundFile));
            else
               Set(FilesList, FileIter, 0, Simple_Name(FoundFile));
            end if;
         end if;
         Set(FilesList, FileIter, 1, "");
      end loop;
      End_Search(Files);
      Set_Sort_Column_Id(FilesList, 0, Sort_Ascending);
   end LoadDirectory;

   procedure CreateMainWindow(NewBuilder: Gtkada_Builder) is
   begin
      Builder := NewBuilder;
      Register_Handler(Builder, "Main_Quit", Quit'Access);
      Register_Handler(Builder, "Resize_Paned", ResizePaned'Access);
      Do_Connect(Builder);
      LoadDirectory(Value("HOME"));
      Show_All(Gtk_Widget(Get_Object(Builder, "mainwindow")));
   end CreateMainWindow;

end MainWindow;

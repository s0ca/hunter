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

with Ada.Command_Line; use Ada.Command_Line;
with Ada.Directories; use Ada.Directories;
with Ada.Environment_Variables; use Ada.Environment_Variables;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with Gtk.Main; use Gtk.Main;
with Gtkada.Bindings; use Gtkada.Bindings;
with Gtkada.Intl; use Gtkada.Intl;
with ErrorDialog; use ErrorDialog;
with LibMagic; use LibMagic;
with Inotify; use Inotify;
with MainWindow; use MainWindow;
with RefreshData; use RefreshData;

procedure Hunter is
begin
   if not Ada.Environment_Variables.Exists("RUNFROMSCRIPT") then
      Put_Line
        ("The program can be run only via 'hunter.sh' script. Please don't run binary directly.");
      return;
   end if;
   -- Start Gettext internationalization
   Setlocale;
   Bind_Text_Domain("hunter", Value("LOCALESDIR"));
   Text_Domain("hunter");
   if not Ada.Directories.Exists(Value("HOME") & "/.cache/hunter") then
      Create_Path(Value("HOME") & "/.cache/hunter");
   end if;
   if not Ada.Directories.Exists
       (Value("HOME") & "/.local/share/Trash/files") then
      Create_Path(Value("HOME") & "/.local/share/Trash/files");
   end if;
   if not Ada.Directories.Exists
       (Value("HOME") & "/.local/share/Trash/info") then
      Create_Path(Value("HOME") & "/.local/share/Trash/info");
   end if;
   -- Start libmagic data
   MagicOpen;
   -- Start inotify
   InotifyInit;
   -- Start GTK
   Init;
   Set_On_Exception(On_Exception'Access);
   if Argument_Count < 1 then
      CreateMainWindow(Value("HOME"));
   else
      CreateMainWindow(Full_Name(Argument(1)));
   end if;
   CreateErrorUI;
   Ld_Library_Path := To_Unbounded_String(Value("LD_LIBRARY_PATH"));
   Clear("LD_LIBRARY_PATH");
   Clear("GDK_PIXBUF_MODULE_FILE");
   Clear("GDK_PIXBUF_MODULEDIR");
   Clear("FONTCONFIG_FILE");
   Clear("RUNFROMSCRIPT");
   Clear("GSETTINGS_BACKEND");
   Main;
   abort InotifyTask;
   InotifyClose;
   MagicClose;
exception
   when An_Exception : others =>
      SaveException(An_Exception, True);
end Hunter;

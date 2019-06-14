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

with Gtkada.Builder; use Gtkada.Builder;

-- ****h* Hunter/Preferences
-- FUNCTION
-- Provide code for save/restore and manipulate the program settings
-- SOURCE
package Preferences is
-- ****

   -- ****t* Preferences/Settings_Data
   -- FUNCTION
   -- Data structure to the program settings
   -- SOURCE
   type Settings_Data is record
      ShowHidden: Boolean; -- If true, show hidden files
   end record;
   -- ****
   -- ****v* Preferences/Settings
   -- FUNCTION
   -- The program settings
   -- SOURCE
   Settings: Settings_Data;
   -- ****

   -- ****f* Preferences/TogglePreferences
   -- FUNCTION
   -- Show or hide the program preferences window
   -- PARAMETERS
   -- Object - GtkAda Builder used to create UI
   -- SOURCE
   procedure TogglePreferences(Object: access Gtkada_Builder_Record'Class);
   -- ****
   -- ****f* Preferences/LoadSettings
   -- FUNCTION
   -- Load the program settings from file. If file not exists, load default
   -- settings.
   -- SOURCE
   procedure LoadSettings;
   -- ****
   -- ****f* Preferences/SaveSettings
   -- FUNCTION
   -- Save the program settings to file and update program to the new
   -- configuration if needed.
   -- PARAMETERS
   -- Object - GtkAda Builder used to create UI
   -- RESULT
   -- Always False so default handler will be running too.
   -- SOURCE
   function SaveSettings
     (Object: access Gtkada_Builder_Record'Class) return Boolean;
   -- ****

end Preferences;
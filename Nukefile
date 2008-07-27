;; Nukefile for Heimat Mac

;; HeimatMac. Easy membership management.
;; Copyright (c) 2008 Peter Quade

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


;; source files
(set @nu_files    (filelist "^nu/.*nu$"))

;; application description
(set @application              "HeimatMac")
(set @application_identifier   "de.pqua.heimatmac")
(set @icon_files (filelist "^resources/[^/]*\.icns$"))
(set @application_icon_file "heimatmac.icns")
(set @resources (array "resources/Credits.html"))

;; (set @application_resource_localized_dir "#{@application_resource_dir}/German.lproj")

(set @nib_files                (filelist "^resources/.*\.lproj/[^/]*\.nib$"))
(set xib_files                 (filelist "^resources/.*\.lproj/[^/]*\.xib$"))
(set @datamodels (filelist "^data/.*\.xcdatamodel$"))

;; tasks
(compilation-tasks)
(application-tasks)

(set @application_icon_file "heimatmac.icns")


(xib_files each:
     (do (xib_file)
         (set xib_file_name ((xib_file componentsSeparatedByString:"/") lastObject))
         (set nib_file_name "#{@application_resource_localized_dir}/")
         (nib_file_name appendString:((xib_file fileName) stringByReplacingPathExtensionWith:"nib"))
         (file nib_file_name => xib_file is
               (SH "ibtool --errors --warning --notices --output-format human-readable-text --compile '#{(target name)}' '#{xib_file}'"))
         (task nib_file_name => "application_resources")
         (task "application" => nib_file_name)))



(task "default" => "application")




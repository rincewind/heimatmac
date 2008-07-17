;; Nukefile for Heimat Mac

;; source files
(set @nu_files    (filelist "^nu/.*nu$"))

;; application description
(set @application              "HeimatMac")
(set @application_identifier   "de.pqua.heimatmac")
;; (set @application_resource_localized_dir "#{@application_resource_dir}/German.lproj")

(set @nib_files                (filelist "^resources/.*\.lproj/[^/]*\.nib$"))
(set xib_files                 (filelist "^resources/.*\.lproj/[^/]*\.xib$"))


;; tasks
(application-tasks)

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




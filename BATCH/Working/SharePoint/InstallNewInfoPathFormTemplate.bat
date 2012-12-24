::BATCH script to upload / install a new infopath form template, and activate it for a particular site collection (uses STSADM commands)
::Publish the form to a location lets say it is published at C:\InfoPathForms\Publish\sample.xsn
cd C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\BIN
::uncomment the below three lines if you want to uninstall and re-install the infopath form template
::stsadm.exe -o DeActivateFormTemplate -url http://demosite -filename ::C:\InfoPathForms\Publish\sample.xsn
::stsadm.exe -o RemoveFormTemplate C:\InfoPathForms\Publish\sample.xsn
::stsadm.exe -o execadmsvcjobs
stsadm.exe -o verifyformtemplate -filename C:\InfoPathForms\Publish\sample.xsn
stsadm.exe -o UploadFormTemplate -filename C:\InfoPathForms\Publish\sample.xsn
stsadm.exe -o execadmsvcjobs
stsadm.exe -o ActivateFormTemplate -url http://demosite -filename C:\InfoPathForms\Publish\sample.xsn
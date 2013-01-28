## SharePoint Server: PowerShell Script To Update All Sites Request Access Email Addresses ##

## Environments: MOSS 2007 and SharePoint Server 2010 / 2013 Farms

## Overview: PowerShell script that updates the Object Model 'RequestAccessEmail' property on all sites within a Web Application

## Usage: Update the '$SPweb.RequestAccessEmail' variable with an email address to suite your environment and run the script providing a Web App URL when prompted

## Resource: http://www.sharepointdiary.com/2012/06/change-all-sites-access-request-emails.html

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null

#For SharePoint 2007 compatibility

function global:Get-SPSite($url){

    return new-Object Microsoft.SharePoint.SPSite($url)

}

#Get the web application

Write-Host "Enter the Web Application URL:"

$WebAppURL= Read-Host

$SiteColletion = Get-SPSite($WebAppURL)

$WebApp = $SiteColletion.WebApplication

 

   # Get All site collections

    foreach ($SPsite in $webApp.Sites)

    {

       # get the collection of webs

       foreach($SPweb in $SPsite.AllWebs)

        {

              # if a site inherits permissions, then the Access request mail setting also will be inherited

             if (!$SPweb.HasUniquePerm)

               {

                  Write-Host "Inheriting from Parent site"

               }

             else

           {

              #$SPweb.RequestAccessEnabled=$true

              $SPweb.RequestAccessEmail ="support@yourdomain.com" #Change this email address to suit your environment

              $SPweb.Update()

           }

        }

    }

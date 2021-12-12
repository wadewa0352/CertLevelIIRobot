# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library     RPA.Browser.Selenium
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.Archive
Library     RPA.Dialogs
Library     RPA.Robocorp.Vault

# -

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order  

*** Keywords ***
Get Secrets From Vault
    ${secret}=    Get Secret    credentials
    # Note: in real robots, you should not print secrets to the log. this is just for demonstration purposes :)
    Log    ${secret}[username]
    Log    ${secret}[password]

*** keywords ***
Ask for Orders Url
    Add text input    ordersUrl    label=Orders Url
    ${response}=    Run dialog
    [Return]    ${response.ordersUrl}

*** Keywords ***
Download orders file
    [Arguments]    ${ordersUrl}
    Download    ${ordersUrl}  overwrite=True

*** Keywords ***
Get orders
   ${orders}=    Read table from CSV    orders.csv
   [Return]    ${orders}

*** keywords ***
Close the annoying modal
    Click Element When Visible  css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

*** keywords ***
Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    ${radioId}=    Catenate    SEPARATOR=   id:id-body-    ${row}[Body]
    Click Element   ${radioId}
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]         
    Input Text    id:address    ${row}[Address]  


*** keywords ***
Preview the robot
    Click Button    id:preview

*** keywords ***
Submit the order
    Click Button    id:order
    Wait Until Element Is Visible    id:order-completion    

*** keywords ***
Store the receipt as a PDF file
    [arguments]    ${orderNumber}    
    ${order_results_html}=    Get Element Attribute    id:order-completion    innerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}receipts${/}order_results_${orderNumber}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}order_results_${orderNumber}.pdf


*** keywords ***
Take a screenshot of the robot
    [arguments]    ${orderNumber}    
    Capture Element Screenshot    id:robot-preview    ${OUTPUT_DIR}${/}receipts${/}order_preview_${orderNumber}.png
    [Return]    ${OUTPUT_DIR}${/}receipts${/}order_preview_${orderNumber}.png

*** keywords ***
Embed the robot screenshot to the receipt PDF file    
    [arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    True


*** keywords ***
Go to order another robot
    Click Button    id:order-another

*** keywords ***
Create a ZIP file of the receipts
    Archive Folder With ZIP   ${OUTPUT_DIR}${/}receipts${/}  ${OUTPUT_DIR}${/}receipts.zip   recursive=True  include=*.pdf


*** Tasks ***
Order robots from RobotSpareBin Industries Inc 
    Get Secrets From Vault
    ${url}=    Ask for Orders Url
    Download orders file    ${url}
    ${orders}=    Get orders
    Open the robot order website    
    FOR    ${row}    IN    @{orders} 
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    3 x    8 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]        
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Close Browser


package screens.ios;

import java.util.List;

//import org.apache.xmlbeans.impl.xb.xsdschema.ListDocument.List;
import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebElement;

import Test.BaseClass;
import Utility.UtilitiesIOS;
import io.appium.java_client.AppiumDriver;

public class AdvertiserIOS extends BaseClass {

	public AppiumDriver driver;
	UtilitiesIOS util = new UtilitiesIOS(driver);

	By configure = By.xpath("//XCUIElementTypeButton[@name='Configure']");
	By advertiser = By.xpath("//XCUIElementTypeButton[@name='ADVERTISER']");
	By gattConfig = By.xpath("//XCUIElementTypeButton[@name='GATT CONFIGURATOR']");
	By createNew = By.xpath("//XCUIElementTypeButton[@name='Create New']");
	By advName = By.xpath("//XCUIElementTypeStaticText[@index=6]");
	By toggleButton = By.xpath("//XCUIElementTypeStaticText[@name='New Advertiser']/following::XCUIElementTypeOther[@index=7]");
	By edit = By.xpath("//XCUIElementTypeButton[@name='EditDisabled']");
	By copy = By.xpath("//XCUIElementTypeButton[@name='icon   copy']");
	By delete = By.xpath("//XCUIElementTypeButton[@name='sil trash']");
	By dropdownArrow = By.xpath("//XCUIElementTypeImage[@name='chevron.down']");
	By readAdvValues = By.xpath("//android.widget.TextView[@resource-id='com.siliconlabs.bledemo:id/tv_details']");
	By deviceName = By.xpath("//XCUIElementTypeButton[@name='deviceRenameIcon']");
	By cancelDevicename = By.xpath("//XCUIElementTypeButton[@name='Cancel']");
	By enterDeviceName = By.xpath("//XCUIElementTypeTextField[@value='iPhone']");
	By enterDeviceName1 = By.xpath("//XCUIElementTypeStaticText[@value='The name will appear in the scan results']/following::XCUIElementTypeTextField");
	By saveDeviceName = By.xpath("//XCUIElementTypeButton[@name='Save']");
	By cancelDeleteAdvPopup = By.xpath("//XCUIElementTypeButton[@name='Cancel']");
	By okAdvPopup = By.xpath("//XCUIElementTypeButton[@name='OK']");
    By remAdvToggle = By.xpath("//XCUIElementTypeWindow/XCUIElementTypeOther[3]/XCUIElementTypeOther[1]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther");
	By switchOff = By.xpath("//XCUIElementTypeButton[@name='disableAllIcon']");
	By backAdvScreen = By.xpath("//XCUIElementTypeButton[@name='Back']");
	By noSaveButton = By.xpath("//XCUIElementTypeButton[@name='No']");
	By yesSaveButton = By.xpath("//XCUIElementTypeButton[@name='Yes']");
	By advNameOnEditScreen = By.xpath("//XCUIElementTypeButton[@name='Back']/following::XCUIElementTypeStaticText[@index=1]");
	By advSetNameHeading = By.xpath("//XCUIElementTypeStaticText[@value='Advertising Set Name']");
	By advSetNameTextbox = By.xpath("//XCUIElementTypeStaticText[@value='Advertising Set Name']/following::XCUIElementTypeTextField");
	By saveAdv = By.xpath("//XCUIElementTypeButton[@name='save']");
	By advDataHeading = By.xpath("//XCUIElementTypeStaticText[@value='Advertising Data']");
	By addAdvDataType = By.xpath("//XCUIElementTypeButton[@name='Add Data Type']");
	By scanResponseDataHeading = By.xpath("//XCUIElementTypeStaticText[@value='Scan Response Data']");
	By addScanDataType = By.xpath("//XCUIElementTypeButton[@name='Add Data Type']");
	By advDataBytes = By.xpath("//XCUIElementTypeStaticText[contains(text(),'Flags and TX Power will be added automatically, their values are managed internally by the system.')]");
	By scanResponseDataBytes = By.xpath("//XCUIElementTypeStaticText[contains(text(),'bytes available')]");	
	By advParametersHeading = By.xpath("//XCUIElementTypeStaticText[@value='Advertising Parameters']");
	By advTimeLimitHeading = By.xpath("//XCUIElementTypeStaticText[@value='Advertising Time Limit']");
	By noLimit = By.xpath("//XCUIElementTypeButton[@name='radio button selected']");
	By timeLimit = By.xpath("//XCUIElementTypeButton[@name='radio button active']");
	By editTimeLimit = By.xpath("//XCUIElementTypeTextField[@value=10 and @index=1]");


	public AdvertiserIOS(AppiumDriver driver)
	{
		this.driver=driver;
	}
	public void advertiserIOS() throws Exception
	{
		try
		{
			Thread.sleep(3000);
			util.elements(driver, configure, "", "", "", "Configure should be clickable", util.timeFunc());
			util.elements(driver, gattConfig, "", "", "", "Gatt Configurator should be clickable", util.timeFunc());
			util.elements(driver, advertiser, "", "", "", "Advertiser should be clickable", util.timeFunc());
			util.elements(driver, createNew, "EFRTEST-218", "", "Tap Create new button (+)", "New Advertiser appears on the list", util.timeFunc());
			util.textDynamicValues(driver, advName,"EFRTEST-218","", "Check new Advertiser's UI", "Name is New adv", util.timeFunc());
			util.elements(driver, dropdownArrow, "EFRTEST-219", "User can expand Advertiser's details", "Tap on Advertiser list item", "Advertiser's details are displayed", util.timeFunc());
			util.elements(driver, dropdownArrow, "EFRTEST-219", "User can expand Advertiser's details", "Tap on Advertiser list item again", "Advertiser's details hide", util.timeFunc());
			util.elements(driver, deviceName, "EFRTEST-220", "User can change device name", "Tap Device name button", "Device name window appears", util.timeFunc());
			util.elements(driver, cancelDevicename, "EFRTEST-220", "User can change device name", "Tap outside of Device name window", "Device name window is closeds", util.timeFunc());
			util.elements(driver, deviceName, "EFRTEST-220", "User can change device name", "Open Device name window again", "Device name window is opened", util.timeFunc());
			util.elements(driver, enterDeviceName, "EFRTEST-220", "User can change device name", "Tap Clear button", "All characters from input field disappear ", util.timeFunc());
			driver.findElement(enterDeviceName).clear();
			util.elements(driver, enterDeviceName1, "EFRTEST-220", "User can change device name", "Enter new name in input field", "New name appears", util.timeFunc());
			driver.findElement(enterDeviceName1).sendKeys("iPhone123"); 
			util.elements(driver, cancelDevicename, "EFRTEST-220", "User can change device name", "Tap Cancel button", "Device name window is closed", util.timeFunc());
			util.elements(driver, deviceName, "EFRTEST-220", "User can change device name", "Open Device name window again", "Name is not changed", util.timeFunc());
			Thread.sleep(3000);
			util.elements(driver, enterDeviceName, "EFRTEST-220", "User can change device name", "Type new name again", "New name appears", util.timeFunc());
			driver.findElement(enterDeviceName).clear();
			driver.findElement(enterDeviceName1).sendKeys("iPhone123");
			util.elements(driver, saveDeviceName, "EFRTEST-220", "User can change device name", "Tap Save button", "Device name window is closed", util.timeFunc());
			util.elements(driver, deviceName, "EFRTEST-220", "User can change device name", "Open Device name window again", "New name is displayed", util.timeFunc());
			Thread.sleep(2000);
			util.elements(driver, saveDeviceName, "EFRTEST-220", "User can change device name", "Tap Save button again to close the popup", "Device name window is closed", util.timeFunc());
			Thread.sleep(2000);
			util.elements(driver, toggleButton, "EFRTEST-221", "User can turn on advertising", "Tap Advertiser's toggle switch", "Advertising is turned on and Toggle switch turns into blue", util.timeFunc());
			Thread.sleep(2000);
			util.elements(driver, toggleButton, "EFRTEST-221", "User can turn on advertising", "Tap Advertiser's toggle switch again", "Advertising is turned off and Toggle switch turns into grey", util.timeFunc());
			util.elements(driver, delete, "EFRTEST-222", "User can delete Advertiser", "Tap Advertiser's delete button", "Remove Advertiser? window appears", util.timeFunc());
			util.elements(driver, cancelDeleteAdvPopup, "EFRTEST-222", "User can delete Advertiser", "Tap Cancel button", "Remove Advertiser? window is closed", util.timeFunc());
			util.elements(driver, delete, "EFRTEST-222", "User can delete Advertiser", "Tap Advertiser's delete button again", "Remove Advertiser? window appears", util.timeFunc());
			Thread.sleep(2000);
			util.elements(driver, okAdvPopup, "EFRTEST-222", "User can delete Advertiser", "Tap Ok button", "Remove Advertiser? window disappears and Advertiser is removed from the list ", util.timeFunc());
			util.elements(driver, createNew, "", "", "Tap Create new button", "New Advertiser appears on the list", util.timeFunc());
			util.elements(driver, delete, "EFRTEST-222", "User can delete Advertiser", "Tap another Advertiser's delete button", "Remove Advertiser? window appears", util.timeFunc());
			util.elements(driver, remAdvToggle, "EFRTEST-222", "User can delete Advertiser", "Check Do not ask me again checkbox", "Checkbox selected", util.timeFunc());
			Thread.sleep(2000);
			util.elements(driver, okAdvPopup, "EFRTEST-222", "User can delete Advertiser", "Tap Ok button", "Remove Advertiser? window disappears and Advertiser is removed from the list ", util.timeFunc());  

			////////////////////////////// [EFRTEST-224] User can copy existing Advertiser ///////////////////////////

			util.elements(driver, createNew, "", "", "Tap Create new button", "New Advertiser appears on the list", util.timeFunc());
			util.elements(driver, copy, "EFRTEST-224", "User can copy existing Advertiser", "Tap Advertiser's copy button", "A copy of Advertiser is created ", util.timeFunc());
			//	util.advTextReading(driver, dropdownArrow, "EFRTEST-224", "User can copy existing Advertiser", "Tap on both Advertiser list items", "Advertiser's details are displayed and Details of both Advertisers are the same", util.timeFunc());

			///////////////////////////////////// [EFRTEST-225] User can turn off all Advertisers at once ///////////////////////////


			List<WebElement> count = driver.findElements(toggleButton);
			System.out.println("Total Toggle button: " + count.size());
			count.get(0).click();
			Thread.sleep(2000);
			count.get(1).click();
			Thread.sleep(2000);
			util.elements(driver,switchOff, "EFRTEST-225", "User can turn off all Advertisers at once", "Tap Switch all OFF button", "Advertising of all Advertisers is turned off", util.timeFunc());			
			util.toggleButtonDisable(driver, toggleButton, "EFRTEST-225", "User can turn off all Advertisers at once", "", "Advertising of all Advertisers should turned off", util.timeFunc());

			/////////////////////// [EFRTEST-226] User can edit Advertiser’s details //////////////////////

			util.elements(driver, delete, "", "", "Tap Advertiser's delete button", "Advertiser should be deleted", util.timeFunc());
			Thread.sleep(2000);
			util.elements(driver, edit, "EFRTEST-226", "User can edit Advertiser’s detail", "Tap edit button", "Advertiser details view is opened", util.timeFunc());
			util.textDynamicValues(driver, advNameOnEditScreen, "EFRTEST-226", "User can edit Advertiser’s detail", "Check Advertiser details view UI", "Advertiser’s name should display", util.timeFunc());
			util.textDynamicValues(driver, advSetNameHeading, "EFRTEST-226", "User can edit Advertiser’s detail", "Check Advertiser details view UI", "Advertising Set name Heading should display", util.timeFunc());
			util.textDynamicValues(driver, advDataHeading, "EFRTEST-226", "User can edit Advertiser’s detail", "Check Advertiser details view UI", "Advertising Data Heading should display", util.timeFunc());
			util.textDynamicValues(driver, scanResponseDataHeading, "EFRTEST-226", "User can edit Advertiser’s detail", "Check Advertiser details view UI", "Scan Response Data Heading should display", util.timeFunc());
			util.textDynamicValues(driver, advParametersHeading, "EFRTEST-226", "User can edit Advertiser’s detail", "Check Advertiser details view UI", "Advertising Parameters Heading should display", util.timeFunc());	
			util.textDynamicValues(driver, advTimeLimitHeading, "EFRTEST-226", "User can edit Advertiser’s detail", "Check Advertiser details view UI", "Advertising Time Limit Heading should display", util.timeFunc());	


			/////////////////////[EFRTEST-227] User can change Advertiser’s name /////////////////////////////

			util.elements(driver, advSetNameTextbox, "EFRTEST-227", "User can change Advertiser’s name", "Tap Advertising Set Name input field", "Field becomes editable", util.timeFunc());
			driver.findElement(advSetNameTextbox).clear();
			Thread.sleep(1000);
			util.elements(driver, advSetNameTextbox, "EFRTEST-227", "User can change Advertiser’s name", "Enter new Advertiser’s name", "New name appears in input field as you write", util.timeFunc());
			driver.findElement(advSetNameTextbox).sendKeys("Advertiser 1");
			Thread.sleep(2000);
			util.elements(driver, backAdvScreen, "EFRTEST-227", "User can change Advertiser’s name", "Tap back button", "Unsaved Changes pop-up appears", util.timeFunc());
			util.elements(driver, noSaveButton, "EFRTEST-227", "User can change Advertiser’s name", "Tap No button", "Advertiser details view is closed", util.timeFunc());
			util.elements(driver, edit, "EFRTEST-227", "User can change Advertiser’s name", "Tap Advertiser’s edit button", "Advertiser details view is active", util.timeFunc());
			util.textDynamicValues(driver, advSetNameTextbox, "", "", "", "Advertiser’s name is not changed", util.timeFunc());
			driver.findElement(advSetNameTextbox).clear();
			util.elements(driver, advSetNameTextbox, "EFRTEST-227", "User can change Advertiser’s name", "Change Advertiser’s name again", "New name appears in input field as you write", util.timeFunc());
			driver.findElement(advSetNameTextbox).sendKeys("Advertiser 1");
			util.elements(driver, saveAdv, "EFRTEST-227", "User can change Advertiser’s name", "Tap view save button", "Advertiser details view is closed", util.timeFunc());
			util.textDynamicValues(driver, advName, "", "", "", "Advertiser’s name is changed", util.timeFunc()); 

			////////////////////////// [EFRTEST-228] User can choose Advertising Type ///////////////////////

			/* Not available in IOS */			


			/////////////////////////// [EFRTEST-229] User can add Advertising/Scan Response Data ///////////////////////

			util.elements(driver, edit, "", "", "Tap Advertiser’s edit button", "Advertiser details view is active", util.timeFunc());
			util.textDynamicValues(driver, advDataHeading, "EFRTEST-229", "User can add Advertising/Scan Response Data", "Check Advertising Data Heading is displaying", "Advertising Data Heading should display", util.timeFunc());
			util.textDynamicValues(driver, scanResponseDataHeading, "EFRTEST-229", "User can add Advertising/Scan Response Data", "Check Scan Response Data Heading is displaying", "Scan Response Data Heading should display", util.timeFunc());		
			util.textDynamicValues(driver, addAdvDataType, "EFRTEST-229", "User can add Advertising/Scan Response Data", "Check Add Data Type button is displayed", " Advertising Add Data Type button is displayed", util.timeFunc());
			util.textDynamicValues(driver, addScanDataType, "EFRTEST-229", "User can add Advertising/Scan Response Data", "Check Add Data Type button is displayed", "Scan Response Add Data Type button is displayed", util.timeFunc());

			/* Remaining functionality Not available in IOS */	

            driver.navigate().back();
			
		/*	Thread.sleep(8000);
			System.out.println("........test......." + driver.getPageSource());
			Thread.sleep(15000); */

		}
		catch(NoSuchElementException e)
		{

			System.out.println("Exception is : " + e.getMessage());		
			Thread.sleep(5000);
		} 	
	}

}

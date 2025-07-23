package screens.ios;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.Keys;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.safari.SafariDriver;

import Test.BaseClass;
import Utility.UtilitiesIOS;
import io.appium.java_client.AppiumBy;
import io.appium.java_client.AppiumDriver;

public class GattConfigIOS extends BaseClass {
	public AppiumDriver driver;
	UtilitiesIOS util = new UtilitiesIOS(driver);

	By configure = By.xpath("//XCUIElementTypeButton[@name='Configure']");
	By gattConfig = By.xpath("//XCUIElementTypeButton[@name='GATT CONFIGURATOR']");
	By toggleButton = By.xpath("//XCUIElementTypeOther[@index=8]");
	By createNew = By.xpath("//XCUIElementTypeButton[@name='Create New']");
	By editIcon = By.xpath("//XCUIElementTypeButton[@name='EditDisabled']");
	By deleteIcon = By.xpath("//XCUIElementTypeButton[@name='sil trash']");
	By okDelete = By.xpath("//XCUIElementTypeButton[@name='OK']");
    By remAdvToggle = By.xpath("//XCUIElementTypeWindow/XCUIElementTypeOther[3]/XCUIElementTypeOther[1]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther");
	By copyIcon = By.xpath("//XCUIElementTypeButton[@name='icon   copy']");
	By downIcon = By.xpath("//XCUIElementTypeImage[@name='chevron.down']");
	By gattServerName = By.xpath("//XCUIElementTypeStaticText[@index=7]//preceding::XCUIElementTypeStaticText[@index=6]");
	By servicesCount = By.xpath("//XCUIElementTypeStaticText[@index=6]/following::XCUIElementTypeStaticText[@index=7]");
	By importIcon = By.xpath("//XCUIElementTypeButton[@name='importIcon']");
	By exportIcon = By.xpath("//XCUIElementTypeButton[@name='exportIcon']");
	By backButton = By.xpath("//XCUIElementTypeButton[@name='Back']");
	By gattServerNameOnHeader = By.xpath("//XCUIElementTypeButton[@name='Back']/following::XCUIElementTypeStaticText");
	By gattServerNameTextbox = By.xpath("//XCUIElementTypeTextField[@value='New GATT Server']");
	By gattServerNameTextbox1 = By.xpath("//XCUIElementTypeStaticText[@value='GATT Server Name']/following::XCUIElementTypeTextField");
	By saveButton = By.xpath("//XCUIElementTypeButton[@name='save']");
	By addServiceButton = By.xpath("//XCUIElementTypeButton[@name='Add Service']");
	By serviceNameTextbox = By.xpath("//XCUIElementTypeTextField[@value='Service name']");
	By heartRate = By.xpath("//XCUIElementTypeStaticText[@value='Heart Rate (0x180D)']");
	By UUIDTextbox = By.xpath("//XCUIElementTypeTextField[@value='16/128-bit UUID']");
	By UUIDName = By.xpath("//XCUIElementTypeStaticText[@value='Heart Rate']/following::XCUIElementTypeStaticText");
	By serviceTypeName = By.xpath("//XCUIElementTypeStaticText[@value='0x180D']/following::XCUIElementTypeStaticText");
	By uuid = By.xpath("//XCUIElementTypeStaticText[@value='Tx Power (0x1804)']");
	By addManSerReq = By.xpath("//XCUIElementTypeButton[@name='Add mandatory service requirements']");
	By dropDown = By.xpath("//XCUIElementTypeImage[@name='chevron_collapsed']");
	By clearButton = By.xpath("//XCUIElementTypeButton[@name='Clear']");
	By cancelButton = By.xpath("//XCUIElementTypeButton[@name='Cancel']");
	By saveButtonOnGattWindow = By.xpath("//XCUIElementTypeButton[@name='Save']");
	By addCharsButton = By.xpath("//XCUIElementTypeButton[@name='Add Characteristic']");
	By charsNameTextbox = By.xpath("//XCUIElementTypeTextField[@value='Characteristic name']");
	By aggregate = By.xpath("//XCUIElementTypeStaticText[@value='Aggregate (0x2A5A)']");
	By readToggle = By.xpath("//XCUIElementTypeStaticText[@value='Read']");
	By saveButtonOnGattWindow1 = By.xpath("//XCUIElementTypeButton[@name='Save' and @index=2]");
	By scanTab = By.xpath("//XCUIElementTypeButton[@name='Scan']");
	By filterIcon = By.xpath("//XCUIElementTypeButton[@name='filterIcon']");
	By searchFilter = By.xpath("//XCUIElementTypeTextView[@value='Search by device name']");
	By startScanning = By.xpath("//XCUIElementTypeButton[@name='Start Scanning']");
	By applyFilters = By.xpath("//XCUIElementTypeButton[@name='Apply Filters']");
	By connectThermometer = By.xpath("//*[@name='Thermometer Example']//preceding::XCUIElementTypeButton[@type='XCUIElementTypeButton' and @name='Connect']");
	By localServer = By.xpath("//XCUIElementTypeButton[@name='Local (Server)']");
	By remoteClient = By.xpath("//XCUIElementTypeButton[@name='Remote (Client)']");
	By heartRateText = By.xpath("//XCUIElementTypeButton[@name='Heart Rate']");
	By moreInfo = By.xpath("//XCUIElementTypeButton[@name='More Info']");
	By lessInfo = By.xpath("//XCUIElementTypeButton[@name='Less Info']");
	By readIcon = By.xpath("//XCUIElementTypeButton[@name='Read']");
	By aggregateService = By.xpath("//XCUIElementTypeButton[@name='Aggregate']/following::XCUIElementTypeStaticText");
	By copyService = By.xpath("//XCUIElementTypeButton[@name='copy icon']");
	By removeService = By.xpath("//XCUIElementTypeButton[@name='delete trash']");
	By bluetoothSIG = By.xpath("//XCUIElementTypeButton[@name='Bluetooth SIG']");
	By expandService = By.xpath("//XCUIElementTypeButton[@name='chevron down']");
	By age = By.xpath("//XCUIElementTypeStaticText[@name='Age (0x2A80)']");
	By readCharacteristicsName = By.xpath("//XCUIElementTypeButton[@name='Read']/following::XCUIElementTypeStaticText[1]");
	By readUUIDName = By.xpath("//XCUIElementTypeButton[@name='Read']/following::XCUIElementTypeStaticText[2]");
	By addDescriptor = By.xpath("//XCUIElementTypeButton[@name='Add Descriptor']");
	By editIconChars = By.xpath("//XCUIElementTypeButton[@name='edit icon']");
	By copyIconChars = By.xpath("//XCUIElementTypeButton[@name='chevron up']/following::XCUIElementTypeButton[@name='copy icon']");
	By removeIconChars = By.xpath("//XCUIElementTypeButton[@name='chevron up']/following::XCUIElementTypeButton[@name='delete trash']");
	By descNameTextbox = By.xpath("//XCUIElementTypeTextField[@value='Descriptor name']");
	By charsPresentFormat = By.xpath("//XCUIElementTypeStaticText[@value='Characteristic Presentation Format (0x2904)']");
	By charsUserDesc = By.xpath("//XCUIElementTypeStaticText[@value='Characteristic User Description (0x2901)']");
	By hexText = By.xpath("//XCUIElementTypeTextField[@value='Insert hex']");
	By asciiText = By.xpath("//XCUIElementTypeTextField[@value='Insert text']");
	By readDescriptorName = By.xpath("//XCUIElementTypeStaticText[@value='Descriptors:']/following::XCUIElementTypeStaticText[2]");
	By readDescUUIDName = By.xpath("//XCUIElementTypeStaticText[@value='Descriptors:']/following::XCUIElementTypeStaticText[3]");
	By copyIconDesc = By.xpath("//XCUIElementTypeStaticText[@value='Descriptors:']/following::XCUIElementTypeButton[@name='copy icon']");
	By removeIconDesc = By.xpath("//XCUIElementTypeStaticText[@value='Descriptors:']/following::XCUIElementTypeButton[@name='delete trash']");
	By editIconDesc = By.xpath("//XCUIElementTypeStaticText[@value='Descriptors:']/following::XCUIElementTypeButton[@name='EditDisabled']");
	By healthThermometer = By.xpath("//XCUIElementTypeStaticText[@value='Health Thermometer (0x1809)']");
	By noUnsavedWindow = By.xpath("//XCUIElementTypeButton[@name='No']");
	By scanParameters = By.xpath("//XCUIElementTypeStaticText[@value='Scan Parameters (0x1813)']");
	By yesUnsavedWindow = By.xpath("//XCUIElementTypeButton[@name='Yes']");

	public GattConfigIOS(AppiumDriver driver)
	{
		this.driver=driver;
	}
	public void gattConfigIOS() throws Exception
	{
		try
		{

			Thread.sleep(3000);
			util.elements(driver, configure, "", "", "", "Configure should be clickable", util.timeFunc());
			util.elements(driver, gattConfig, "", "", "", "Gatt Configurator should be clickable", util.timeFunc());
			util.elements(driver, createNew, "", "", "Tap Create new button", "New Gatt Server appears on the list", util.timeFunc());
			util.elements(driver, editIcon, "", "", "Tap edit button", "Gatt Server details view is opened", util.timeFunc());

			////////////////// [EFRTEST-358] User can Read the value of a characteristic in Local view //////////////////

			util.elements(driver, addServiceButton, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Tap Add Service button", "Add a GATT Service window is opened", util.timeFunc());
			util.elements(driver, serviceNameTextbox, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Enter service’s name and UUID", "Service name entered", util.timeFunc());
			driver.findElement(serviceNameTextbox).sendKeys("Heart Rate");
			util.elements(driver, heartRate, "", "", "Select Heart Rate", "Heart Rate is selected", util.timeFunc());
			util.elements(driver, saveButtonOnGattWindow, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Tap Save button", "Window is closed", util.timeFunc());
			util.elements(driver, addCharsButton, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Tap Add characteristic button", "Add a GATT Characteristic window is displayed", util.timeFunc());
			util.elements(driver, charsNameTextbox, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Enter characteristic’s name and UUID", "Name and UUID appear in input fields", util.timeFunc());
			driver.findElement(charsNameTextbox).sendKeys("Aggregate");
			util.elements(driver, aggregate, "", "", "Select Aggregate", "Aggregate is selected", util.timeFunc());
			util.toggleButton(driver, readToggle, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Make sure Read property’s switch is turned on" , "Read property is enabled", util.timeFunc());
			util.elements(driver, saveButtonOnGattWindow, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Tap Save button in Add a GATT Characteristic window" , "Window is closed", util.timeFunc());
			util.elements(driver, saveButton, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Tap Save button" , "Data is saved and GATT Server Configuration view closes", util.timeFunc());
			util.elements(driver, editIcon, "", "", "Tap edit button", "Gatt Server details view is opened", util.timeFunc());
			util.elements(driver, backButton, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Tap back button", "GATT Server main view closes", util.timeFunc());
			util.elements(driver, toggleButton, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Turn on modified GATT Server", "GATT Server is enabled", util.timeFunc());			
			util.elements(driver, scanTab, "", "", "Tap Scan button", "Scan screen view is opened", util.timeFunc());
		//	util.elements(driver, startScanning, "", "", "Tap Start Scanning button", "Connected devices list should display", util.timeFunc());
			util.elements(driver, filterIcon, "", "", "Tap filter icon on top of the screen", "Filter screen view is opened", util.timeFunc());
			driver.findElement(searchFilter).sendKeys("thermometer", Keys.ENTER);
			util.elements(driver, applyFilters, "", "", "Tap Apply filters button", "It will redirect to Scan screen view", util.timeFunc());			
			util.elements(driver, connectThermometer, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Connect with any EFR device", "Connected device view is displayed", util.timeFunc());
			util.elements(driver, localServer, "EFRTEST-358", "User can Read the value of a characteristic in Local view", "Switch to Local tab", "A service and a characteristic that were added to device’s A GATT Server are displayed", util.timeFunc());
			util.textDynamicValues(driver, heartRateText, "EFRTEST-358", "User can Read the value of a characteristic in Local view","", "A service and a characteristic that were added to device’s A GATT Server are displayed", util.timeFunc());
			util.elements(driver, moreInfo, "", "", "Tap more info button", "More Info button turns into Less Info button", util.timeFunc());
			util.elements(driver, readIcon, "EFRTEST-358", "User can Read the value of a characteristic in Local view","Tap Read button next to the characteristic that you added", "Characteristic value is displayed", util.timeFunc());
			util.elements(driver, lessInfo, "", "", "Tap Less info button", "Less Info button turns into More Info button", util.timeFunc());

			//////////////////////////[EFRTEST-357] User can expand services and characteristics in Local view ///////////////////////////////

			util.elements(driver, moreInfo, "EFRTEST-357", "User can expand services and characteristics in Local view", "Tap more info button", "More Info button turns into Less Info button", util.timeFunc());
			util.textDynamicValues(driver, aggregateService, "EFRTEST-357", "User can expand services and characteristics in Local view", "Tap on any expandable service", "All of service’s characteristics are displayed", util.timeFunc());
			util.elements(driver, lessInfo, "EFRTEST-357", "User can expand services and characteristics in Local view", "Tap Less info button", "Less Info button turns into More Info button", util.timeFunc());

            /////////////////////////[EFRTEST-356] User can open Local view ///////////////////////////////

			util.textDynamicValues(driver, remoteClient, "", "", "On device A connect with any EFR device", "At the bottom of the screen there are two tabs: Remote (Client) and Local (Server)", util.timeFunc());
			util.elements(driver, remoteClient, "", "", "Switch to Remote client tab", "A service and a characteristic that were added to device’s A GATT Server are displayed", util.timeFunc());
			util.textDynamicValues(driver, localServer, "", "", "On device A connect with any EFR device", "At the bottom of the screen there are two tabs: Remote (Client) and Local (Server)", util.timeFunc());
			util.elements(driver, backButton, "", "", "Tap back button", "Scan screen view closes", util.timeFunc());


			//////////////////////////[EFRTEST-367] User can create and edit Gatt Server ////////////////////////

			util.elements(driver, configure, "", "", "", "Configure should be clickable", util.timeFunc());
			util.elements(driver, gattConfig, "EFRTEST-367", "User can create and edit Gatt Server", "Tap GATT Configurator", "GATT Configurator view is displayed", util.timeFunc());
			util.elements(driver, deleteIcon, "", "", "Tap delete icon", "Remove GATT server popup is open", util.timeFunc());
			util.elements(driver, okDelete, "", "", "Tap Ok button", "GATT server is deleted", util.timeFunc());
			util.elements(driver, createNew, "EFRTEST-367", "User can create and edit Gatt Server", "Create New GATT Server", "New GATT Server is displayed on the list", util.timeFunc());
			util.textDynamicValues(driver, servicesCount, "EFRTEST-367", "User can create and edit Gatt Server", "", "0 Services is displayed under the name", util.timeFunc());
			util.elements(driver, editIcon, "EFRTEST-367", "User can create and edit Gatt Server", "Select edit icon", "New GATT Server view is displayed", util.timeFunc());
			util.elements(driver, gattServerNameTextbox, "EFRTEST-367", "User can create and edit Gatt Server", "Change the name", "New name is displayed on header", util.timeFunc());
			driver.findElement(gattServerNameTextbox).clear();
			driver.findElement(gattServerNameTextbox1).sendKeys("Gatt Server 1");
			util.elements(driver, saveButton, "EFRTEST-367", "User can create and edit Gatt Server", "Select Save", "GATT Configurator view is displayed", util.timeFunc());
			util.textDynamicValues(driver, gattServerName, "EFRTEST-367", "User can create and edit Gatt Server", "", "GATT Server has new name", util.timeFunc());
			util.elements(driver, editIcon, "", "", "Select edit icon", "New GATT Server view is displayed", util.timeFunc());
			util.textDynamicValues(driver, gattServerNameOnHeader, "EFRTEST-367", "User can create and edit Gatt Server", "Check new name on Gatt server screen header", "GATT Server has new name", util.timeFunc());
			util.elements(driver, backButton, "", "", "Tap back button", "Gatt Server screen view closes", util.timeFunc());

			//////////////////////////[EFRTEST-369] GATT Server can be copied and removed Created ///////////////////

			util.elements(driver, copyIcon, "EFRTEST-369", "GATT Server can be copied and removed Created", "Select copy icon", "Copy of GATT Server is displayed under the original", util.timeFunc());
			List<WebElement> countEdit = driver.findElements(editIcon);
			System.out.println("Total Edit icons are: " + countEdit.size());
			countEdit.get(1).click();
			util.textDynamicValues(driver, gattServerNameOnHeader, "EFRTEST-369", "GATT Server can be copied and removed Created", "Select edit icon", "GATT Server contains the same settings as original GATT Server", util.timeFunc());
			util.elements(driver, backButton, "", "", "Tap back button", "Gatt Server screen view closes", util.timeFunc());
			util.elements(driver, deleteIcon, "EFRTEST-369", "GATT Server can be copied and removed Created", "Select delete icon next to the original GATT Server", "Remove GATT Server?” pop-up is displayed", util.timeFunc());
			util.elements(driver, cancelButton, "EFRTEST-369", "GATT Server can be copied and removed Created", "Tap Cancel", "GATT Server has not been removed", util.timeFunc());
			util.elements(driver, deleteIcon, "EFRTEST-369", "GATT Server can be copied and removed Created", "Select delete icon next to the original GATT Server", "Remove GATT Server?” pop-up is displayed", util.timeFunc());
			util.elements(driver, remAdvToggle, "EFRTEST-369", "GATT Server can be copied and removed Created", "Select “Do not give this warning again” ", "Toggle button should be enable", util.timeFunc());
			util.elements(driver, okDelete, "EFRTEST-369", "GATT Server can be copied and removed Created", "Tap Ok button", "Original GATT Server is removed", util.timeFunc());
			util.elements(driver, deleteIcon, "EFRTEST-369", "GATT Server can be copied and removed Created", "Select delete icon next to the copy of GATT Server", "Copy of GATT Server is removed", util.timeFunc());
			 

			///////////////////////////// [EFRTEST-370] User can add service ////////////////////////////////

			util.elements(driver, createNew, "", "", "Create New GATT Server", "New GATT Server is displayed on the list", util.timeFunc());
			util.elements(driver, editIcon, "", "", "Tap edit button", "Gatt Server details view is opened", util.timeFunc());
			util.elements(driver, addServiceButton, "EFRTEST-370", "User can add service", "Select Add Service", "Add a GATT Service view is displayed", util.timeFunc());
			util.elements(driver, serviceNameTextbox, "EFRTEST-370", "User can add service", "Write service name", "After entering two letters list of suggestions will appear", util.timeFunc());
			driver.findElement(serviceNameTextbox).sendKeys("Heart Rate");
			util.elements(driver, heartRate, "EFRTEST-370", "User can add service", "Select service from the list", "Name and UUID is displayed", util.timeFunc());
			util.elements(driver, saveButtonOnGattWindow, "EFRTEST-370", "User can add service", "Select Save", "Selected service is displayed on the list", util.timeFunc());
			util.textDynamicValues(driver, UUIDName, "EFRTEST-370", "User can add service", "Check new Service", "UUID is displayed under the name", util.timeFunc());
			util.textDynamicValues(driver, serviceTypeName, "EFRTEST-370", "User can add service", "Check new Service", "Primary Service is displayed under the UUID", util.timeFunc());
			if(driver.findElement(copyService).isDisplayed()==true)
			{
				System.out.println("Copy Icon is displayed");
			}
			else
			{
				System.out.println("Copy Icon is not displayed");
			}

			if(driver.findElement(removeService).isDisplayed()==true)
			{
				System.out.println("Remove Icon is displayed");
			}
			else
			{
				System.out.println("Remove Icon is not displayed");
			}
			util.textDynamicValues(driver, addCharsButton, "EFRTEST-370", "User can add service", "Check new Service", "Add Characteristic button is displayed", util.timeFunc()); 
			util.elements(driver, addServiceButton, "EFRTEST-370", "User can add service", "Select Add Service again", "Add a GATT Service view is displayed", util.timeFunc());
			util.elements(driver, serviceNameTextbox, "EFRTEST-370", "User can add service", "Write all service name", "Name is set", util.timeFunc());
			driver.findElement(serviceNameTextbox).sendKeys("Tx Power");
			util.elements(driver, UUIDTextbox, "EFRTEST-370", "User can add service", "Enter UUID", "UUID is set", util.timeFunc());
			driver.findElement(UUIDTextbox).sendKeys("1804");
			util.elements(driver, uuid, "EFRTEST-370", "User can add service", "Select UUID", "UUID is selected", util.timeFunc());
			util.elements(driver, addManSerReq, "EFRTEST-370", "User can add service", "Select Add mandatory service requirements", "Add mandatory service requirements is selected", util.timeFunc());
			util.elements(driver, saveButtonOnGattWindow, "EFRTEST-370", "User can add service", "Select Save", "Selected service is displayed on the list", util.timeFunc());			
			util.elements(driver, copyService, "EFRTEST-370", "User can add service", "Select copy icon", "Copy of service is displayed under the original", util.timeFunc());
			util.elements(driver, removeService, "EFRTEST-370", "User can add service", "Select delete icon", "Original service is removed", util.timeFunc());
			util.elements(driver, addServiceButton, "EFRTEST-370", "User can add service", "Select Add Service again", "Add a GATT Service view is displayed", util.timeFunc());
			//	util.elements(driver, bluetoothSIG, "EFRTEST-370", "User can add service", "Select Bluetooth GATT Services button", "Website with Bluetooth GATT Services is displayed", util.timeFunc());
			//	Thread.sleep(4000);
			//	driver.navigate().back();
			util.elements(driver, cancelButton, "", "", "Tap Cancel", "It will redirect to New Gatt Server screen", util.timeFunc()); 


			///////////////////////////// [EFRTEST-371] User can add characteristic //////////////////////////////////

			util.elements(driver, addCharsButton, "EFRTEST-371", "User can add characteristic", "Select Add Characteristic","Add a GATT Characteristic view is displayed", util.timeFunc());
			util.elements(driver, charsNameTextbox, "EFRTEST-371", "User can add characteristic", "Write characteristic name","After entering two letters list of suggestions will appear", util.timeFunc());
			driver.findElement(charsNameTextbox).sendKeys("Aggregate");
			util.elements(driver, aggregate, "EFRTEST-371", "User can add characteristic", "Select characteristic from the list","Name and UUID is displayed", util.timeFunc());
			util.elements(driver, saveButtonOnGattWindow, "EFRTEST-371", "User can add characteristic", "Select Save","GATT Server view is displayed", util.timeFunc());
			util.elements(driver, expandService, "EFRTEST-371", "User can add characteristic", "Tap on Service","List of characteristics is displayed", util.timeFunc());
			util.elements(driver, addCharsButton, "EFRTEST-371", "User can add characteristic", "Select Add Characteristic","Add a GATT Characteristic view is displayed", util.timeFunc());
			util.elements(driver, charsNameTextbox, "EFRTEST-371", "User can add characteristic", "Write characteristic name","After entering two letters list of suggestions will appear", util.timeFunc());
			driver.findElement(charsNameTextbox).sendKeys("Age");
			util.elements(driver, age, "EFRTEST-371", "User can add characteristic", "Select characteristic from the list","Name and UUID is displayed", util.timeFunc());
			if(driver.findElement(readToggle).isEnabled()==true)
			{
				System.out.println("Read Toggle is already set enabled");
			}
			else
			{
				util.elements(driver, readToggle, "EFRTEST-371", "User can add characteristic", "Set Read enabled","Read property is enabled", util.timeFunc());
			}
			util.elements(driver, saveButtonOnGattWindow, "EFRTEST-371", "User can add characteristic", "Select Save","GATT Server view is displayed", util.timeFunc());
			util.envDynamicValues(driver, readCharacteristicsName, "EFRTEST-371", "User can add characteristic", "Check new characteristic","List of characteristics are displayed", util.timeFunc());
			util.envDynamicValues(driver, readUUIDName, "EFRTEST-371", "User can add characteristic", "Check new characteristic","UUID is displayed under the name", util.timeFunc());
			util.envDynamicValues(driver, readIcon, "EFRTEST-371", "User can add characteristic", "Check new characteristic","Read property is displayed", util.timeFunc());
			util.envDynamicValues(driver, addDescriptor, "EFRTEST-371", "User can add characteristic", "Check new characteristic","Add Descriptor button is displayed", util.timeFunc());
			util.elements(driver, copyIconChars, "EFRTEST-371", "User can add characteristic", "Select copy icon","Copy of characteristic is displayed under the original", util.timeFunc());
			util.elements(driver, removeIconChars, "EFRTEST-371", "User can add characteristic", "Select delete icon","Original characteristic is removed", util.timeFunc());
			util.elements(driver, editIconChars, "EFRTEST-371", "User can add characteristic", "Select edit icon","Add a GATT Characteristic view is displayed", util.timeFunc());
			util.elements(driver, cancelButton, "", "", "Select Cancel button","Gatt Characteristic window should closed", util.timeFunc());


			///////////////////////////// [EFRTEST-372] User can add descriptor ///////////////////////////////

			util.elements(driver, addDescriptor, "EFRTEST-372", "User can add descriptor", "Select Add Descriptor","Add a GATT Descriptor view is displayed", util.timeFunc());
			util.elements(driver, descNameTextbox, "EFRTEST-372", "User can add descriptor", "Write descriptor name","After entering two letters list of suggestions will appear", util.timeFunc());
			driver.findElement(descNameTextbox).sendKeys("Characteristic Presentation Format");
			util.elements(driver, charsPresentFormat, "EFRTEST-372", "User can add descriptor", "Select descriptor from the list","Name and UUID is displayed", util.timeFunc());
			util.elements(driver, hexText, "EFRTEST-372", "User can add descriptor", "Write initial value", "Value is set", util.timeFunc());
			driver.findElement(hexText).sendKeys("01234567890123");
			util.elements(driver, saveButtonOnGattWindow, "EFRTEST-372", "User can add descriptor", "Select Save","GATT Server view with new descriptor is displayed", util.timeFunc());
			util.elements(driver, addDescriptor, "EFRTEST-372", "User can add descriptor", "Select Add Descriptor again","Add a GATT Descriptor view is displayed", util.timeFunc());
			util.elements(driver, descNameTextbox, "EFRTEST-372", "User can add descriptor", "Write descriptor name","After entering two letters list of suggestions will appear", util.timeFunc());
			driver.findElement(descNameTextbox).sendKeys("Characteristic User Description");
			util.elements(driver, charsUserDesc, "EFRTEST-372", "User can add descriptor", "Select descriptor from the list","Name and UUID is displayed", util.timeFunc());
			util.elements(driver, asciiText, "EFRTEST-372", "User can add descriptor", "Write initial value", "Value is set", util.timeFunc());
			driver.findElement(asciiText).sendKeys("bb");
			util.elements(driver, saveButtonOnGattWindow, "EFRTEST-372", "User can add descriptor", "Select Save","GATT Server view with new descriptor is displayed", util.timeFunc());
			util.envDynamicValues(driver, readDescriptorName, "EFRTEST-372", "User can add descriptor", "Check new descriptor","List of descriptors are displayed", util.timeFunc());
			util.envDynamicValues(driver, readDescUUIDName, "EFRTEST-372", "User can add descriptor", "Check new descriptor","UUID is displayed under the name", util.timeFunc());
			util.envDynamicValues(driver, readIcon, "EFRTEST-372", "User can add descriptor", "Check new descriptor","Read property is displayed", util.timeFunc());
			util.envDynamicValues(driver, addDescriptor, "EFRTEST-372", "User can add descriptor", "Check new descriptor","Add Descriptor button is displayed", util.timeFunc());
			util.elements(driver, copyIconDesc, "EFRTEST-372", "User can add descriptor", "Select copy icon","Copy of descriptor is displayed under the original", util.timeFunc());
			util.elements(driver, removeIconDesc, "EFRTEST-372", "User can add descriptor", "Select delete icon","Original descriptor is removed", util.timeFunc());
			util.elements(driver, editIconDesc, "EFRTEST-372", "User can add descriptor", "Select edit icon","Add a GATT descriptor view is displayed", util.timeFunc());
			util.elements(driver, cancelButton, "", "", "Select Cancel button","Gatt descriptor window should closed", util.timeFunc());
			util.elements(driver, saveButton, "", "", "Select Save" , "GATT Configurator view is displayed", util.timeFunc());


			///////////////////////////// [EFRTEST-373] User can exit from GATT Server without saving changes Created ////////////////

			util.elements(driver, createNew, "", "", "Create New GATT Server", "New GATT Server is displayed on the list", util.timeFunc());
			util.elements(driver, editIcon, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Select edit icon", "New GATT Server view is displayed", util.timeFunc());
			util.elements(driver, addServiceButton, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Tap Add Service button", "Add a GATT Service window is opened", util.timeFunc());
			util.elements(driver, serviceNameTextbox, "", "", "Enter service’s name", "New service is added", util.timeFunc());
			driver.findElement(serviceNameTextbox).sendKeys("Health Thermometer");
			util.elements(driver, healthThermometer, "", "", "Select Health Thermometer", "Health Thermometer is selected", util.timeFunc());
			util.elements(driver, saveButtonOnGattWindow, "", "", "Tap Save button", "Window is closed", util.timeFunc());
			util.elements(driver, saveButton, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Select Save" , "GATT Configurator view is displayed", util.timeFunc());
			util.textDynamicValues(driver, servicesCount, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Check number of services", "Number of services increased by one", util.timeFunc());
			util.elements(driver, editIcon, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Select edit icon", "New GATT Server view is displayed", util.timeFunc());

			// scroll down till Add Service Button

			JavascriptExecutor js = (JavascriptExecutor)driver;
			HashMap<String,String> scrollObject = new HashMap<String,String>();
			scrollObject.put("direction", "down");
			js.executeScript("mobile:scroll", scrollObject);
			Thread.sleep(2000);

			util.elements(driver, addServiceButton, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Tap Add Service button", "Add a GATT Service window is opened", util.timeFunc());
			util.elements(driver, serviceNameTextbox, "", "", "Enter service’s name", "New service is added", util.timeFunc());
			driver.findElement(serviceNameTextbox).sendKeys("Heart Rate"); 
			util.elements(driver, heartRate, "", "", "Select Heart Rate", "Heart Rate is selected", util.timeFunc());
			util.elements(driver, saveButtonOnGattWindow, "", "", "Tap Save button", "Window is closed", util.timeFunc());
			util.elements(driver, backButton, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Select back button", "Unsaved changes popup is displayed", util.timeFunc());
			util.elements(driver, noUnsavedWindow, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Tap No", "GATT Configurator view is displayed", util.timeFunc());
			util.textDynamicValues(driver, servicesCount, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Check number of services", "There is no changes", util.timeFunc());
			util.elements(driver, editIcon, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Select edit icon", "New GATT Server view is displayed", util.timeFunc());
			js.executeScript("mobile:scroll", scrollObject);	
			util.elements(driver, addServiceButton, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Tap Add Service button", "Add a GATT Service window is opened", util.timeFunc());
			util.elements(driver, serviceNameTextbox, "", "", "Enter service’s name", "New service is added", util.timeFunc());
			driver.findElement(serviceNameTextbox).sendKeys("Scan Parameters");
			util.elements(driver, scanParameters, "", "", "Select Scan Parameters", "Scan Parameters is selected", util.timeFunc());
			util.elements(driver, saveButtonOnGattWindow, "", "", "Tap Save button", "Window is closed", util.timeFunc());
			util.elements(driver, backButton, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Select back button", "Unsaved changes popup is displayed", util.timeFunc());
			util.elements(driver, yesUnsavedWindow, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Tap Yes", "GATT Configurator view is displayed", util.timeFunc());
			util.textDynamicValues(driver, servicesCount, "EFRTEST-373", "User can exit from GATT Server without saving changes Created", "Check number of services", "Number of services increased by one", util.timeFunc());


            /////////////////////////// [EFRTEST-374] User can clear input fields - service /////////////////////////////////
             
                        util.elements(driver, editIcon, "", "", "Select edit icon", "New GATT Server view is displayed", util.timeFunc());
                        js.executeScript("mobile:scroll", scrollObject);
                        util.elements(driver, addServiceButton, "EFRTEST-374", "User can clear input fields - service", "Select Add Service button", "Add a GATT Service view is displayed", util.timeFunc());
                        util.textboxEmpty(driver, saveButtonOnGattWindow, "EFRTEST-374", "User can clear input fields - service", "Verify Save button is disabled","Button Save is dimmed", util.timeFunc());
                        util.elements(driver, serviceNameTextbox, "", "", "Enter service’s name", "New service is added", util.timeFunc());
                        driver.findElement(serviceNameTextbox).sendKeys("Heart Rate");
                        util.elements(driver, heartRate, "", "", "Select Heart Rate", "Heart Rate is selected", util.timeFunc());
                        util.textboxNotEmpty(driver, saveButtonOnGattWindow, "EFRTEST-374", "User can clear input fields - service", "Verify Save button is enabled","Button Save is blue", util.timeFunc());
                        util.elements(driver, clearButton, "EFRTEST-374", "User can clear input fields - service", "Tap Clear","Inputs with Service name and UUID are cleared", util.timeFunc());
                        util.textboxEmpty(driver, saveButtonOnGattWindow, "EFRTEST-374", "User can clear input fields - service", "Verify Save button is disabled","Button Save is dimmed", util.timeFunc());
                        util.elements(driver, cancelButton, "EFRTEST-374", "User can clear input fields - service", "Tap Cancel","Add a GATT Service view is closed", util.timeFunc());
             
                        HashMap<String,String> scrollObject1 = new HashMap<String,String>();
                        scrollObject1.put("direction", "up");
                        js.executeScript("mobile:scroll", scrollObject1);
                        Thread.sleep(2000);
             
                        /////////////////////////// [EFRTEST-375] User can clear input fields - characteristic ////////////////////////////
             
                        util.elements(driver, addCharsButton, "EFRTEST-375", "User can clear input fields - characteristic", "Select Add Characteristic","Add a GATT Characteristic view is displayed", util.timeFunc());
                        util.textboxEmpty(driver, saveButtonOnGattWindow, "EFRTEST-375", "User can clear input fields - characteristic", "Verify Save button is disabled","Button Save is dimmed", util.timeFunc());
                        util.elements(driver, charsNameTextbox, "EFRTEST-375", "User can clear input fields - characteristic", "Write characteristic name","After entering two letters list of suggestions will appear", util.timeFunc());
                        driver.findElement(charsNameTextbox).sendKeys("Aggregate");
                        util.elements(driver, aggregate, "EFRTEST-375", "User can clear input fields - characteristic", "Select characteristic from the list","Name is displayed", util.timeFunc());
                        util.textboxNotEmpty(driver, saveButtonOnGattWindow, "EFRTEST-375", "User can clear input fields - characteristic", "Verify Save button is enabled","Button Save is blue", util.timeFunc());
                        util.elements(driver, clearButton, "EFRTEST-375", "User can clear input fields - characteristic", "Tap Clear", "Inputs with Characteristic name and UUID are cleared, ", util.timeFunc());
                        util.textboxEmpty(driver, saveButtonOnGattWindow, "EFRTEST-375", "User can clear input fields - characteristic", "Verify Save button is disabled","Button Save is dimmed", util.timeFunc());
                        util.elements(driver, cancelButton, "EFRTEST-375", "User can clear input fields - characteristic", "Tap Cancel","Add a GATT Characteristic view is closed", util.timeFunc());
             
                        /////////////////////////// [EFRTEST-376] User can clear input fields - descriptor /////////////////////////////////
             
                        util.elements(driver, addCharsButton, "", "", "Select Add Characteristic","Add a GATT Characteristic view is displayed", util.timeFunc());
                        util.elements(driver, charsNameTextbox, "", "", "Write characteristic name","After entering two letters list of suggestions will appear", util.timeFunc());
                        driver.findElement(charsNameTextbox).sendKeys("Aggregate");
                        util.elements(driver, aggregate, "", "", "Select characteristic from the list","Name is displayed", util.timeFunc());
                        util.elements(driver, saveButtonOnGattWindow, "", "", "Click Save button","Gatt Characteristic is saved", util.timeFunc());
                        util.elements(driver, expandService, "", "", "Expand service icon","It will display list of characteristic", util.timeFunc());
                        util.elements(driver, addDescriptor, "EFRTEST-376", "User can clear input fields - descriptor", "Select Add Descriptor","Add a GATT Descriptor view is displayed", util.timeFunc());
                        util.textboxEmpty(driver, saveButtonOnGattWindow, "EFRTEST-376", "User can clear input fields - descriptor", "Verify Save button is disabled","Button Save is dimmed", util.timeFunc());
                        util.elements(driver, descNameTextbox, "EFRTEST-376", "User can clear input fields - descriptor", "Write descriptor name","After entering two letters list of suggestions will appear", util.timeFunc());
                        driver.findElement(descNameTextbox).sendKeys("Characteristic Presentation Format");
                        util.elements(driver, charsPresentFormat, "EFRTEST-376", "User can clear input fields - descriptor", "Select descriptor from the list","Name is displayed", util.timeFunc());
                        util.elements(driver, hexText, "EFRTEST-376", "User can clear input fields - descriptor", "Write initial value", "Value is set", util.timeFunc());
                        driver.findElement(hexText).sendKeys("01234567890123");
                        util.textboxNotEmpty(driver, saveButtonOnGattWindow, "EFRTEST-376", "User can clear input fields - descriptor", "Verify Save button is enabled","Button Save is blue", util.timeFunc());
                        util.elements(driver, clearButton, "EFRTEST-376", "User can clear input fields - descriptor", "Tap Clear", "Inputs with Descriptor name and UUID are cleared, ", util.timeFunc());
                        util.textboxEmpty(driver, saveButtonOnGattWindow, "EFRTEST-376", "User can clear input fields - descriptor", "Verify Save button is disabled","Button Save is dimmed", util.timeFunc());
                        util.elements(driver, cancelButton, "EFRTEST-376", "User can clear input fields - descriptor", "Tap Cancel","Add a GATT Descriptor view is closed", util.timeFunc());
                        util.elements(driver, saveButton, "", "", "Select Save" , "GATT Configurator view is displayed", util.timeFunc());

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

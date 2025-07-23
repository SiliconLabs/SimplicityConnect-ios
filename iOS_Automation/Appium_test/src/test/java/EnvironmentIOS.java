package screens.ios;

import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;

import Test.BaseClass;
import Utility.UtilitiesIOS;
import io.appium.java_client.AppiumDriver;

public class EnvironmentIOS extends BaseClass
{

	public AppiumDriver driver;
	UtilitiesIOS util = new UtilitiesIOS(driver);

	By environment = By.xpath("//XCUIElementTypeStaticText[@name='Environment']");
	By thunderboard = By.xpath("//XCUIElementTypeStaticText[@name='Thunderboard #25954' or @name='Thunderboard #26004']");	
	By temperature= By.xpath("//XCUIElementTypeStaticText[@name='Temperature']/following::XCUIElementTypeStaticText");
	By humidity= By.xpath("//XCUIElementTypeStaticText[@name='Humidity']/following::XCUIElementTypeStaticText");
	By ambientLight= By.xpath("//XCUIElementTypeStaticText[@name='Ambient Light']/following::XCUIElementTypeStaticText");
	By soundLevel= By.xpath("//XCUIElementTypeStaticText[@name='Sound Level']/following::XCUIElementTypeStaticText");
	By magneticField= By.xpath("//XCUIElementTypeStaticText[@name='Magnetic Field']/following::XCUIElementTypeStaticText");
	By doorState= By.xpath("//XCUIElementTypeStaticText[@name='Door State']/following::XCUIElementTypeStaticText");
	By settings = By.xpath("//XCUIElementTypeButton[@name='developOff']");
	By celsiusTemp = By.xpath("//XCUIElementTypeButton[@name='C']");
	By FTemp = By.xpath("//XCUIElementTypeButton[@name='F']");
//	By usbPower = By.xpath("//android.widget.TextView[@class='android.widget.TextView' and @text='USB Power']");
	By deviceNotFound= By.xpath("//XCUIElementTypeStaticText[@name='Please connect a device' or @name='N/A']");
	By cancelButton = By.xpath("//XCUIElementTypeStaticText[@name='Cancel']");
    By backButton = By.xpath("//XCUIElementTypeButton[@name='Back']");
	
	public EnvironmentIOS(AppiumDriver driver)
	{
		this.driver=driver;
	}
	public void environmentIOS() throws Exception
	{
		try
		{

			Thread.sleep(3000);		
			System.out.println("Test Environment");
			Thread.sleep(5000);
			util.elements(driver, environment,"EFRTEST-326","Environment view","Tap Environment button","Environment should be clickable", util.timeFunc());
				Thread.sleep(5000);

			if (driver.findElement(thunderboard).isDisplayed()) {

				util.elements(driver, thunderboard,"EFRTEST-326","Environment view","Select any available device","Thunderboard should be clickable", util.timeFunc());
				Thread.sleep(5000);
				if(driver.findElement(environment).isDisplayed())
				{
				//	System.out.println(driver.findElement(temperature).getText());
			//	util.textDynamicValues(driver, temperature,"EFRTEST-326","Environment view","UI elements are shown", "Environment values should display", util.timeFunc());
				Thread.sleep(3000);
				util.elements(driver, settings,"EFRTEST-316","Settings view is closed when user presses back/close","Tap back/close button","Environment values should display", util.timeFunc());
				driver.navigate().back();
				util.elements(driver, settings,"EFRTEST-328","User can change the units in Environment view","Tap Settings button","Settings icon should be clickable", util.timeFunc());
				util.elements(driver,celsiusTemp ,"EFRTEST-328","User can change the units in Environment view","Change the unit of temperature","Celsius icon should be clickable and Unit should changed", util.timeFunc());
				Thread.sleep(5000);
				driver.navigate().back();
				util.textDynamicValues(driver, temperature,"EFRTEST-328","User can change the units in Environment view","Tap back/close button", "Environment values should display and temperature for Celsius", util.timeFunc());	
				util.textDynamicValues(driver, humidity,"","","", "Humidity value should display", util.timeFunc());
				util.textDynamicValues(driver, ambientLight,"","","", "Ambient Light value should display", util.timeFunc());
				util.textDynamicValues(driver, soundLevel,"","","", "Sound Level value should display", util.timeFunc());
				util.textDynamicValues(driver, doorState,"","","", "Door State value should display", util.timeFunc());
				util.textDynamicValues(driver, magneticField,"","","", "Magnetic Field value should display", util.timeFunc());
				Thread.sleep(2000);		
				util.elements(driver, settings,"EFRTEST-328","User can change the units in Environment view","Tap Settings button again","Settings icon should be clickable", util.timeFunc());
				util.elements(driver, FTemp,"EFRTEST-328","User can change the units in Environment view","Change the unit of temperature again","F icon should be clickable and Unit should changed", util.timeFunc());
				driver.navigate().back();
				util.textDynamicValues(driver, temperature,"EFRTEST-328","User can change the units in Environment view","Tap back/close button", "Environment values should display and temperature for F", util.timeFunc());
				util.textDynamicValues(driver, humidity,"","","", "Humidity value should display", util.timeFunc());
				util.textDynamicValues(driver, ambientLight,"","","", "Ambient Light value should display", util.timeFunc());
				util.textDynamicValues(driver, soundLevel,"","","", "Sound Level value should display", util.timeFunc());
				util.textDynamicValues(driver, doorState,"","","", "Door State value should display", util.timeFunc());
				util.textDynamicValues(driver, magneticField,"","","", "Magnetic Field value should display", util.timeFunc());
				util.textDynamicValues(driver, thunderboard,"","","", "Connected To: ", util.timeFunc());
				
				//	util.textDynamicValues(driver, usbPower,"EFRTEST-378","Device connection method icon","Check the device connection method icon", "USB Power with USB sign should display", util.timeFunc());
				Thread.sleep(4000);
				}
				util.elements(driver, backButton,"EFRTEST-327","Environment view is closed when user presses back","Tap back button","Back button should be clickable", util.timeFunc());
			    
			//	System.out.println("........test......." + driver.getPageSource());
			//		Thread.sleep(15000);

			}
		}
		catch(NoSuchElementException e)
		{

			System.out.println("Exception is : " + e.getMessage());		
			Thread.sleep(5000);
			util.deviceNotAvailable(driver,deviceNotFound,"","","","Device should be available", util.timeFunc());
			Thread.sleep(3000);
			util.elements(driver, cancelButton,"","","", "Cancel Button should be clickable", util.timeFunc());
		} 

	}}

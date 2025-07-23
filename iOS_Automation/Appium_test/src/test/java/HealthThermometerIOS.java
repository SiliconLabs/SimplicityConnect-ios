package screens.ios;

import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;

import Test.BaseClass;
import Utility.UtilitiesIOS;
import io.appium.java_client.AppiumDriver;

public class HealthThermometerIOS extends BaseClass {

	public AppiumDriver driver;
	UtilitiesIOS util = new UtilitiesIOS(driver);

	By healthThermometer = By.xpath("//XCUIElementTypeStaticText[@name='Health Thermometer']");
	By thermometerExample = By.xpath("//XCUIElementTypeStaticText[@name='Thermometer Example']");
	By connectedTo = By.xpath("//XCUIElementTypeStaticText[@name='CONNECTED TO :']/following::XCUIElementTypeStaticText");
	By type = By.xpath("//XCUIElementTypeStaticText[@name='TYPE']/following::XCUIElementTypeStaticText");
	By Ftoggle = By.xpath("//XCUIElementTypeStaticText[@name='ºF']");
	By Ctoggle = By.xpath("//XCUIElementTypeStaticText[@name='ºC']");
	By tempF = By.xpath("//XCUIElementTypeStaticText[@name='TEMPERATURE']/following::XCUIElementTypeStaticText");
	//	By tempC = By.xpath("//XCUIElementTypeStaticText[@name='TEMPERATURE']/following::XCUIElementTypeStaticText");
	By deviceNotFound= By.xpath("//XCUIElementTypeStaticText[@name='Please connect a device' or @name='N/A']");
	By cancelButton = By.xpath("//XCUIElementTypeStaticText[@name='Cancel']");
	By backButton = By.xpath("//XCUIElementTypeButton[@name='Back']");

	public HealthThermometerIOS(AppiumDriver driver)
	{
		this.driver=driver;
	}
	public void healthThermometerIOS() throws Exception
	{
		try
		{
			util.elements(driver, healthThermometer,"EFRTEST-140","Connected device view is displayed when user selects available device","Tap Health Thermometer button","Health Thermometer should be clickable", util.timeFunc());
			Thread.sleep(3000);
			if (driver.findElement(thermometerExample).isDisplayed()) {
				util.elements(driver, thermometerExample,"EFRTEST-140","Connected device view is displayed when user selects available device","Select any available device","Thermometer Example should be clickable", util.timeFunc());
				Thread.sleep(2000);
				util.textDynamicValues(driver, connectedTo, "EFRTEST-145","Current temperature is shown","Check UI of displayed screen and check if all elements are available","Connected To value should display", util.timeFunc());
				util.textDynamicValues(driver, type,"EFRTEST-145","Current temperature is shown","Check UI of displayed screen and check if all elements are available", "Type should display", util.timeFunc());
				Thread.sleep(5000);			
				util.elements(driver, Ctoggle,"EFRTEST-147","Value of temperature is updated when user changes the unit","Change the unit ºF to ºC","Switching the toggle button should be clickable", util.timeFunc());
				Thread.sleep(4000);
				util.dynamicValuesIOS(driver, tempF,"EFRTEST-147","Value of temperature is updated when user changes the unit","Change the unit ºF to ºC", "Value of temperature should be updated and ºC is displayed on the button", util.timeFunc());
				util.elements(driver, Ftoggle,"EFRTEST-147","Value of temperature is updated when user changes the unit","Change the unit ºC to ºF","Switching the toggle button should be clickable", util.timeFunc());
				util.dynamicValuesIOS(driver, tempF,"EFRTEST-147","Value of temperature is updated when user changes the unit","Change the unit ºC to ºF", "Value of temperature should be updated and ºF is displayed on the button", util.timeFunc());			
				Thread.sleep(3000);
				util.elements(driver, backButton,"EFRTEST-141","Health Thermometer app view is closed when user presses back","Tap back button","Back button should be clickable", util.timeFunc());

			//	System.out.println("........test......." + driver.getPageSource());
			//	Thread.sleep(15000);

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
	}
}

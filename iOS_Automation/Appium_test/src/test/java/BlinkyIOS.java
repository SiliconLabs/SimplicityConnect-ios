package screens.ios;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Set;

import org.openqa.selenium.By;
import org.openqa.selenium.ElementNotInteractableException;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.Color;
import io.appium.java_client.remote.SupportsContextSwitching;
import Test.BaseClass;
import Utility.UtilitiesIOS;
import io.appium.java_client.AppiumDriver;

public class BlinkyIOS extends BaseClass
{
	public AppiumDriver driver;
	UtilitiesIOS util = new UtilitiesIOS(driver);



	By blinky = By.xpath("//XCUIElementTypeStaticText[@name='Blinky']");
	By thunderboard = By.xpath("//XCUIElementTypeStaticText[@name='Thunderboard #25954' or @name='Thunderboard #26004']");
	//	By thunderboard1 = By.xpath("//android.widget.TextView[@class='android.widget.TextView' and @text='Blinky Example']");
	By lightbulb = By.xpath("//XCUIElementTypeButton[@name='lightOff']");
	//	By virtualButton = By.xpath("//android.widget.ImageView[@index='2' and @content-desc='button']");
	//	By usbPower = By.xpath("//XCUIElementTypeImage[@name='icon - usb - opt2']");
	By deviceNotFound= By.xpath("//XCUIElementTypeStaticText[@name='Please connect a device' or @name='N/A']");
	By cancelButton = By.xpath("//XCUIElementTypeStaticText[@name='Cancel']");
	By backButton = By.xpath("//XCUIElementTypeButton[@name='Back']");




	public BlinkyIOS(AppiumDriver driver)
	{
		this.driver=driver;
	}
	public void blinkyIOS() throws Exception
	{
		try
		{

			Thread.sleep(3000);		
			System.out.println("Test Blinky");
			//	util.elements(driver, demo,"","","","Demo should be clickable", util.timeFunc());
			Thread.sleep(5000);
			util.elements(driver, blinky,"EFRTEST-350", "Blinky view is displayed when board is connected", "Tap on Blinky demo", "Blinky should be clickable",  util.timeFunc());
			Thread.sleep(10000);

			if (driver.findElement(thunderboard).isDisplayed()) {

				//	util.elements(driver, thunderboard1,"Thunderboard should be clickable", filepath + "TC3.png");
				util.elements(driver, thunderboard,"EFRTEST-350", "Blinky view is displayed when board is connected", "Tap on board’s name","Thunderboard should be clickable", util.timeFunc());
				Thread.sleep(5000);
				if(driver.findElement(blinky).isDisplayed())
				{
					Thread.sleep(5000);
					util.textDynamicValues(driver, blinky,"EFRTEST-351", "Check Blinky’s view initial UI ","Check Blinky view","Blinky heading should be display", util.timeFunc());
				}
				Thread.sleep(5000);
				util.elements(driver, lightbulb,"EFRTEST-353","User can turn on/off the LED on the kit","Tap the light icon","Lightbulb should be turned on and Light icon is yellow",util.timeFunc());
				Thread.sleep(5000);
				util.elements(driver, lightbulb,"EFRTEST-353","User can turn on/off the LED on the kit","Tap the light icon again","Lightbulb should be turned off and Light icon is grey", util.timeFunc());
				Thread.sleep(5000);
				//		util.elements(driver, lightbulb,"Lightbulb should be turned on",util.timeFunc());
				Thread.sleep(5000);
				//		util.elements(driver, lightbulb,"Lightbulb should be turned off", util.timeFunc());
				Thread.sleep(5000);
				util.textDynamicValues(driver, thunderboard,"","","", "Thunderboard #25954 should display", util.timeFunc());
				//	util.textDynamicValues(driver, usbPower,"EFRTEST-377","Device connection method icon","Check the device connection method icon", "USB Power with USB sign should display", util.timeFunc());
				Thread.sleep(2000);
				util.elements(driver, backButton,"EFRTEST-352","Blinky view is closed when user taps back button","Tap back button","Back button should be clickable and Demo view should display", util.timeFunc());			
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


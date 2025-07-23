package screens.ios;

import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;

import Test.BaseClass;
import Utility.UtilitiesIOS;
import io.appium.java_client.AppiumDriver;

public class MotionIOS extends BaseClass{
	public AppiumDriver driver;
	UtilitiesIOS util = new UtilitiesIOS(driver);


	By motion = By.xpath("//XCUIElementTypeStaticText[@name='Motion']");
	By thunderboard = By.xpath("//XCUIElementTypeStaticText[@name='Thunderboard #25954' or @name='Thunderboard #26004']");
//	By usbPower = By.xpath("//android.widget.TextView[@class='android.widget.TextView' and @text='USB Power']");
	By orientationX = By.xpath("//XCUIElementTypeStaticText[@name='X:' and @index='3']/following::XCUIElementTypeStaticText");
	By orientationY = By.xpath("//XCUIElementTypeStaticText[@name='Y:' and @index='5']/following::XCUIElementTypeStaticText");
	By orientationZ = By.xpath("//XCUIElementTypeStaticText[@name='Z:' and @index='7']/following::XCUIElementTypeStaticText");	
	By accelerationX = By.xpath("//XCUIElementTypeStaticText[@name='X:' and @index='9']/following::XCUIElementTypeStaticText");
	By accelerationY = By.xpath("//XCUIElementTypeStaticText[@name='Y:' and @index='11']/following::XCUIElementTypeStaticText");
	By accelerationZ = By.xpath("//XCUIElementTypeStaticText[@name='Z:' and @index='13']/following::XCUIElementTypeStaticText");
	By calibrate = By.xpath("//XCUIElementTypeStaticText[@name='Calibrate']");
	By deviceNotFound= By.xpath("//XCUIElementTypeStaticText[@name='Please connect a device' or @name='N/A']");
	By cancelButton = By.xpath("//XCUIElementTypeStaticText[@name='Cancel']");
	By backButton = By.xpath("//XCUIElementTypeButton[@name='Back']");

	public MotionIOS(AppiumDriver driver)
	{
		this.driver=driver;
	}

	public void motionIOS() throws Exception
	{
		try
		{

			Thread.sleep(3000);		
			util.elements(driver, motion,"EFRTEST-323","Motion view","Tap Motion button","Motion should be clickable", util.timeFunc());
			Thread.sleep(5000);
			if (driver.findElement(thunderboard).isDisplayed()) {
				util.elements(driver, thunderboard,"EFRTEST-323","Motion view","Select any available device","Thunderboard should be clickable", util.timeFunc());
				Thread.sleep(6000);			
				util.elements(driver, calibrate,"EFRTEST-323","Motion view","Tap CALIBRATE button","Calibrate button should be clickable", util.timeFunc());
				Thread.sleep(2000);
				System.out.println("Test X started");
				util.textDynamicValues(driver, orientationX,"EFRTEST-323","Motion view","","After Calibrating Orientation X value should display", util.timeFunc());
            	System.out.println("Test Y started");
				util.textDynamicValues(driver, orientationY,"EFRTEST-323","Motion view","","After Calibrating Orientation Y value should display", util.timeFunc());
				System.out.println("Test Z started");
				util.textDynamicValues(driver, orientationZ,"EFRTEST-323","Motion view","","After Calibrating Orientation Z value should display", util.timeFunc());
				System.out.println("Test X started for Accer");
				util.textDynamicValues(driver, accelerationX,"EFRTEST-323","Motion view","","After Calibrating Acceleration X value should display", util.timeFunc());
				System.out.println("Test Y started for Accer");
				util.textDynamicValues(driver, accelerationY,"EFRTEST-323","Motion view","","After Calibrating Acceleration Y value should display", util.timeFunc());
				System.out.println("Test Z started for Accer");
				util.textDynamicValues(driver, accelerationZ,"EFRTEST-323","Motion view","","After Calibrating Acceleration Z value should display", util.timeFunc());
					Thread.sleep(2000); 
				System.out.println("Reading thunderboard and USB power");
				util.textDynamicValues(driver, thunderboard,"","","", "Thunderboard #25954 should display", util.timeFunc());
				
			//	util.textDynamicValues(driver, usbPower,"EFRTEST-314","Device connection method icon","Check the device connection method icon", "USB Power with USB sign should display", util.timeFunc());
						Thread.sleep(5000);
				util.elements(driver, backButton,"EFRTEST-324","Motion view is closed when user presses back","Tap back button","Back button should be clickable and User is redirected to Demo view ", util.timeFunc());
			
				
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
			util.elements(driver, cancelButton,"","","","Cancel Button should be clickable", util.timeFunc());
		}
	}
}

package screens.ios;

import org.openqa.selenium.By;

import Test.BaseClass;
import Test.IOSDriverConfig;
import Utility.UtilitiesIOS;
import io.appium.java_client.AppiumDriver;

public class SettingsIOS extends IOSDriverConfig{
	
	public AppiumDriver driver;
	UtilitiesIOS util = new UtilitiesIOS(driver);
	
	By settings = By.xpath("//XCUIElementTypeButton[@name='Settings']");
	By version = By.xpath("//XCUIElementTypeStaticText[contains(@name,'App version')]");
	
	
	public SettingsIOS(AppiumDriver driver)
	{
		this.driver=driver;
	}
	
	public void settingsIOS() throws Exception
	{
		try
		{   Thread.sleep(8000);
			util.elements(driver, settings, "", "", "", "Settings should be clickable", util.timeFunc());
			util.textDynamicValues(driver, version, "", "", "", "Version of app is", util.timeFunc());
		//	Thread.sleep(8000);
		//	System.out.println("........test......." + driver.getPageSource());
		//	Thread.sleep(15000);
		}
		catch(Exception e)
		{
			System.out.println("Exception is : " + e.getMessage());	
		}
	}

}

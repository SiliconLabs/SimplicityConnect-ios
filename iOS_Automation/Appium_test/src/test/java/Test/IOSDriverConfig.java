package Test;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.util.concurrent.TimeUnit;
import org.apache.commons.io.FileUtils;
import org.openqa.selenium.By;
import org.openqa.selenium.remote.DesiredCapabilities;
import Utility.UtilitiesIOS;
import io.appium.java_client.AppiumDriver;
import io.appium.java_client.ios.IOSDriver;
import io.appium.java_client.remote.IOSMobileCapabilityType;
import io.appium.java_client.remote.MobileCapabilityType;
import screens.ios.AdvertiserIOS;
import screens.ios.BlinkyIOS;
import screens.ios.EnvironmentIOS;
import screens.ios.GattConfigIOS;
import screens.ios.HealthThermometerIOS;
import screens.ios.MotionIOS;
import screens.ios.SettingsIOS;
import screens.ios.ThroughputIOS;

public class IOSDriverConfig {

	public static AppiumDriver driver;
	UtilitiesIOS utilIOS = new UtilitiesIOS(driver);
	By demo1 = By.xpath("//XCUIElementTypeButton[@name='Demo']");

	String filepathIOS = System.getProperty("user.dir") + "//Excel/ReportIOS.xlsx";
	String filepath = System.getProperty("user.dir") + "//Screenshots//IOS/";


	public void iOSSetUp() throws IOException, InterruptedException
	{

		DesiredCapabilities capabilities = new DesiredCapabilities();

		capabilities.setCapability("appium:automationName", "xcuitest");
		capabilities.setCapability("appium:platformVersion", "17.5");
		capabilities.setCapability("appium:deviceName", "iPhone 13");
		capabilities.setCapability("platformName", "iOS");
		capabilities.setCapability(IOSMobileCapabilityType.WDA_LAUNCH_TIMEOUT,60000);
	//	capabilities.setCapability("udid","00008110-000131522620201E");
		capabilities.setCapability("udid","00008110-001130EE1EEA401E");
		capabilities.setCapability("bundleID","com.silabs.BlueGeckoDemoApp");
		capabilities.setCapability("xcodeOrgID","52444FG85C");
		capabilities.setCapability("xcodeSigingId","iPhone Developer");
		capabilities.setCapability(MobileCapabilityType.NEW_COMMAND_TIMEOUT,10000);
		capabilities.setCapability("appium:app", "/Users/jenkins/ios_app/BlueGecko.app");
	//	capabilities.setCapability("appium:app", "/Users/negulati/Downloads/BlueGecko 7.app");
		capabilities.setCapability("autoGrantPermissions", "true");
		capabilities.setCapability("autoAcceptAlerts", "true");
	

		driver = new IOSDriver(new URL("http://127.0.0.1:4723/wd/hub"), capabilities);
		driver.manage().timeouts().implicitlyWait(30, TimeUnit.SECONDS);
		System.out.println("Launch the IOS EFRConnect Application..");
		
		File f1 = new File(filepathIOS);
		if(f1.delete())
		{
		System.out.println(f1.getName() + " file deleted successfully..");
		}
		else  
		{  
		System.out.println("failed");  
		}  

		File f = new File(filepath);
		FileUtils.deleteDirectory(f);
		f.delete();
		System.out.println("Screenshot folder deleted successfully..");
		
	/*	Thread.sleep(8000);
		System.out.println("........test......." + driver.getPageSource());
		Thread.sleep(15000); */
	}

	public void settings() throws Exception
	{
		Thread.sleep(3000);
		SettingsIOS s1 = new SettingsIOS(driver);
		s1.settingsIOS();
		System.out.println("Demo is clickable");
		Thread.sleep(5000);
		utilIOS.elements(driver, demo1,"","","","IOS Demo should be clickable", utilIOS.timeFunc());
	}
	public void demoScreen() throws Exception
	{
		BlinkyIOS b = new BlinkyIOS(driver);
		b.blinkyIOS();
		HealthThermometerIOS ht = new HealthThermometerIOS(driver);
		ht.healthThermometerIOS();
		EnvironmentIOS e = new EnvironmentIOS(driver);
		e.environmentIOS();
		ThroughputIOS t = new ThroughputIOS(driver);
		t.throughputIOS();
		MotionIOS m = new MotionIOS(driver);
		m.motionIOS(); 
	}
	
	public void configureScreen() throws Exception
	{
		AdvertiserIOS a = new AdvertiserIOS(driver);
		a.advertiserIOS();
		GattConfigIOS g = new GattConfigIOS(driver);
		g.gattConfigIOS();
		
	
	}
	public void quit() throws InterruptedException
	{
		driver.quit();
	}
}

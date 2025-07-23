package Test;
import java.io.IOException;
import java.net.URL;
import java.util.concurrent.TimeUnit;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.testng.annotations.AfterTest;
import org.testng.annotations.Test;
import io.appium.java_client.AppiumDriver;
import io.appium.java_client.android.AndroidDriver;
import io.appium.java_client.ios.IOSDriver;
import io.appium.java_client.remote.IOSMobileCapabilityType;
import io.appium.java_client.remote.MobileCapabilityType;



public class BaseClass {

	public static AppiumDriver driver;


	@Test(priority=1)
	public void iOSSetUp() throws IOException, InterruptedException
	{

		DesiredCapabilities capabilities = new DesiredCapabilities();

		capabilities.setCapability("appium:automationName", "xcuitest");
		capabilities.setCapability("appium:platformVersion", "17.5");
		capabilities.setCapability("appium:deviceName", "iPhone 13");
		capabilities.setCapability("platformName", "iOS");
		capabilities.setCapability(IOSMobileCapabilityType.WDA_LAUNCH_TIMEOUT,60000);
		capabilities.setCapability("udid","00008110-001130EE1EEA401E");
		capabilities.setCapability("bundleID","com.silabs.BlueGeckoDemoApp");
		capabilities.setCapability("xcodeOrgID","52444FG85C");
		capabilities.setCapability("xcodeSigingId","iPhone Developer");
		capabilities.setCapability(MobileCapabilityType.NEW_COMMAND_TIMEOUT,10000);
		capabilities.setCapability("appium:app","/Users/jenkins/ios_app/BlueGecko.app");
		capabilities.setCapability("autoGrantPermissions", "true");
		capabilities.setCapability("autoAcceptAlerts", "true");

		driver = new IOSDriver(new URL("http://127.0.0.1:4723/wd/hub"), capabilities);
		driver.manage().timeouts().implicitlyWait(30, TimeUnit.SECONDS);
		System.out.println("Launch the IOS EFRConnect Application..");
	}

	@AfterTest
	public void quit() throws InterruptedException
	{
		Thread.sleep(3000);
		driver.quit();
		System.out.println("........quit.......");
	}

}

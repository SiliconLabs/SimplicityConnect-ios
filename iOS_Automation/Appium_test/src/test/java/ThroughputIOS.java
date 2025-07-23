package screens.ios;

import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;

import Test.BaseClass;
import Utility.UtilitiesIOS;
import io.appium.java_client.AppiumDriver;

public class ThroughputIOS extends BaseClass{

	public AppiumDriver driver;
	UtilitiesIOS util = new UtilitiesIOS(driver);


	By throughput = By.xpath("//XCUIElementTypeStaticText[@name='Throughput']");
	By throughputTest = By.xpath("//XCUIElementTypeStaticText[@name='Throughput Test']");
	By notifications = By.xpath("//XCUIElementTypeStaticText[@name='Notifications']");
	By indications = By.xpath("//XCUIElementTypeStaticText[@name='Indications']");
	By startButton = By.xpath("//XCUIElementTypeStaticText[@name='Start']");
	By stopButton = By.xpath("//XCUIElementTypeStaticText[@name='Stop']");
	By PHYStatus = By.xpath("//XCUIElementTypeStaticText[contains(@name,'PHY:')]");
	By intervalStatus = By.xpath("//XCUIElementTypeStaticText[contains(@name,'Interval:')]");
	By latencyValue = By.xpath("//XCUIElementTypeStaticText[contains(@name,'Latency:')]");
	By supervisionTimeoutValue = By.xpath("//XCUIElementTypeStaticText[contains(@name,'Supervision Timeout:')]");
	By PDUValue = By.xpath("//XCUIElementTypeStaticText[contains(@name,'PDU:')]");
	By MTUValue = By.xpath("//XCUIElementTypeStaticText[contains(@name,'MTU:')]");
	By deviceNotFound= By.xpath("//XCUIElementTypeStaticText[@name='Please connect a device' or @name='N/A']");
	By cancelButton = By.xpath("//XCUIElementTypeStaticText[@name='Cancel']");
	By backButton = By.xpath("//XCUIElementTypeButton[@name='Back']");

//	By indicationDynamicValues = By.xpath("//android.view.View[@resource-id='android:id/content']/android.widget.FrameLayout/android.view.View");
	
	public ThroughputIOS(AppiumDriver driver)
	{
		this.driver=driver;
	}

	public void throughputIOS() throws Exception
	{
		try
		{
			Thread.sleep(3000);
			util.elements(driver, throughput,"EFRTEST-336","Throughput view is displayed when board is connected","Tap on Throughput demo","Throughput should be clickable", util.timeFunc());
			Thread.sleep(5000);


			if (driver.findElement(throughputTest).isDisplayed()) {

				util.elements(driver, throughputTest,"EFRTEST-336","Board appears on available device’s list","Tap on board’s name","Throughput Test should be clickable", util.timeFunc());
				Thread.sleep(5000);
				if(driver.findElement(throughput).isDisplayed())
				{
					Thread.sleep(5000);
					util.textDynamicValues(driver, throughput,"EFRTEST-337", "Check Throughput’s view initial UI","Check Throughput view UI","Throughput heading should be display", util.timeFunc());
				}
				Thread.sleep(5000);
				if(driver.findElement(notifications).isEnabled())
				{
					Thread.sleep(2000);
					util.elements(driver, startButton,"EFRTEST-338", "Start button turns into Stop button when there is an ongoing test","Choose any mode and tap Start button", "Start button should be clickable and turns into Stop button", util.timeFunc());
					Thread.sleep(6000);
					util.textDynamicValues(driver, PHYStatus,"EFRTEST-337", "Check Throughput’s view initial UI","Check Throughput view UI", "PHY value should be display", util.timeFunc());
					util.textDynamicValues(driver, intervalStatus, "EFRTEST-337", "Check Throughput’s view initial UI","Check Throughput view UI","Interval value should be display", util.timeFunc());
					util.textDynamicValues(driver, latencyValue,"EFRTEST-337", "Check Throughput’s view initial UI","Check Throughput view UI", "Latency value should be display", util.timeFunc());
					util.textDynamicValues(driver, supervisionTimeoutValue,"EFRTEST-337", "Check Throughput’s view initial UI","Check Throughput view UI", "Supervision Timeout should be display", util.timeFunc());
					util.textDynamicValues(driver, PDUValue,"EFRTEST-337", "Check Throughput’s view initial UI","Check Throughput view UI", "PDU value should be display", util.timeFunc());
					util.textDynamicValues(driver, MTUValue,"EFRTEST-337", "Check Throughput’s view initial UI","Check Throughput view UI", "MTU value should be display", util.timeFunc());
					util.elements(driver, stopButton,"EFRTEST-338", "Stop button turns into Start button when there is an ongoing test","Tap Stop button", "Stop button should be clickable and turns into Start button", util.timeFunc());
					Thread.sleep(6000);
				}
				if(driver.findElement(indications).isEnabled())
				{
					util.elements(driver, indications,"EFRTEST-339","User can switch between Notifications and Indications modes","Tap Indications mode", "Indications radio button should be clickable", util.timeFunc());
					util.elements(driver, startButton,"EFRTEST-339","User can switch between Notifications and Indications modes","Tap Start button", "Start button should be clickable and turns into Stop button", util.timeFunc());
					util.elements(driver, stopButton,"EFRTEST-339", "User can switch between Notifications and Indications modes","Tap Stop button", "Stop button should be clickable and turns into Start button", util.timeFunc());
					util.elements(driver, backButton,"EFRTEST-343","Throughput view is closed when user taps back button","Tap back button","Back button should be clickable and User is redirected to Demo view", util.timeFunc());
				//	util.elements(driver, backButton,"EFRTEST-344","Test is stopped when user taps back button","Tap back button","Back button should be clickable and User is redirected to Demo view", util.timeFunc());
					Thread.sleep(6000);
				} 
				//	System.out.println("........test......." + driver.getPageSource());
				//	Thread.sleep(15000);
			}
		}
		catch(NoSuchElementException e)
		{

			System.out.println("Exception is : " + e.getMessage());		
			Thread.sleep(5000);
			util.deviceNotAvailable(driver,deviceNotFound,"EFRTEST-348","Unavailable board is not displayed in Select a Bluetooth device window","Tap on Throughput demo","Device should be available", util.timeFunc());
			Thread.sleep(3000);
			util.elements(driver, cancelButton,"","", "","Cancel Button should be clickable", util.timeFunc());
		} 
	}

}

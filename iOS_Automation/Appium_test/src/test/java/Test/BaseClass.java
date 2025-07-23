package Test;


import org.testng.annotations.AfterTest;
import org.testng.annotations.Test;


public class BaseClass {
	
	IOSDriverConfig iphone = new IOSDriverConfig();
 
	
	@Test(priority=0)
//	@Test(enabled=false)
	public void iPhone() throws Exception
	{
		
		iphone.iOSSetUp();
		iphone.settings();
		iphone.demoScreen();
		iphone.configureScreen(); 
	} 
	


	@AfterTest
	public void quit() throws InterruptedException
	{
		Thread.sleep(5000);
		iphone.quit();
		System.out.println("........quit.......");
	}

}


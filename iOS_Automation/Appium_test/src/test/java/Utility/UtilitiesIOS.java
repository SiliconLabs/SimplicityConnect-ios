package Utility;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Date;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.apache.commons.io.FileUtils;
import org.openqa.selenium.By;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebElement;

import io.appium.java_client.AppiumDriver;

public class UtilitiesIOS {
	
	public AppiumDriver driver;

	Date d = new Date();
	static int count= 0;
	String filepath;
	
	

	ExcelOutputIOS e = new ExcelOutputIOS();

	public UtilitiesIOS(AppiumDriver driver)
	{
		this.driver=driver;
	}

	public void elements(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res, String filepath) throws IOException
	{
		try
		{
			if(driver.findElement(ele).isDisplayed())
			{
				driver.findElement(ele).click();
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Element is clickable","Pass",filepath);

			}
			else

			{
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Element is not clickable","Fail",filepath);
				
			}
		}
		catch(Exception e)
		{
			e.getMessage();
		}
	}
	
	
	public void screenshots(AppiumDriver driver,String filepath) throws IOException
	{
	
		TakesScreenshot srcShot = ((TakesScreenshot)driver);
		File srcFile = srcShot.getScreenshotAs(OutputType.FILE);
		File destFile = new File(filepath);
		FileUtils.copyFile(srcFile, destFile); 
	} 

	public String timeFunc()
	{ 
		filepath = System.getProperty("user.dir") + "//Screenshots//IOS/" + "TC " + ++count + " " + d.toString().replace(":", "_").replace(" ", "_") + ".png";
		return filepath;
	}

	public void deviceNotAvailable(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String filepath) throws IOException
	{
		try
		{
			if(driver.findElement(ele).isDisplayed())
			{
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Please connect a device or N/A","Fail",filepath);
				Thread.sleep(3000);
			}			
		} 
		catch(Exception e)
		{
			e.getMessage();
		} 
	}

	public void textDynamicValues(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String filepath)
	{
		try
		{
			if(driver.findElement(ele).isDisplayed())
			{
				String text = driver.findElement(ele).getText();
				System.out.println("The text is: " + text);
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Value is: " + text,"Pass",filepath);
			}
			else

			{
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Element is not displaying","Fail",filepath);
			}
		}
		catch(Exception e)
		{
			e.getMessage();
		}
	}

	public void dynamicValues(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String filepath)
	{
		try
		{
			if(driver.findElement(ele).isDisplayed())
			{
				List<WebElement> allText= driver.findElements(ele);
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Value is: " + allText.get(4).getText() + allText.get(5).getText() + allText.get(6).getText(),"Pass",filepath);
			}
			else

			{
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Element is not displaying","Fail",filepath);
			}
		}
		catch(Exception e)
		{
			e.getMessage();
		}
	}

	public void dynamicValuesIOS(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String filepath)
	{
		try
		{
			if(driver.findElement(ele).isDisplayed())
			{
				List<WebElement> allText= driver.findElements(ele);
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Value is: " + allText.get(0).getText() + "." + allText.get(3).getText() + allText.get(1).getText(),"Pass",filepath);
			}
			else

			{
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Element is not displaying","Fail",filepath);
			}
		}
		catch(Exception e)
		{
			e.getMessage();
		}
	}
	
	public void envDynamicValues(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String filepath)
	{
		try
		{
			if(driver.findElement(ele).isDisplayed())
			{
				List<WebElement> allText= driver.findElements(ele);
				for(int i=0;i<allText.size();i++)
				{
					String	text = allText.get(i).getText();
					System.out.println("The text is: " + text); 
					screenshots(driver,filepath);
					e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Value is: " + allText.get(i).getText(),"Pass",filepath);
				}}
			else

			{
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Element is not displaying","Fail",filepath);
			}
		}
		catch(Exception e)
		{
			e.getMessage();
		}
	}
	
	public void toggleButton(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String filepath)
	{
		try
		{
			if(driver.findElement(ele).isEnabled()==true)
			{
				System.out.println("Read Toggle button is enabled");
				screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Toggle button is enabled","Pass",filepath);
			}
			else
			{
				System.out.println("Read Toggle button is disabled");
			    screenshots(driver,filepath);
				e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Toggle button is disabled","Fail",filepath);
				}
		}
			
		catch(Exception e)
		{
			e.getMessage();
		}
	}
	
	public void toggleButtonDisable(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String filepath)
	{
		try
		{
		List<WebElement> countToggle = driver.findElements(ele);
		if(countToggle.get(0).isEnabled()== false)
		{
			System.out.println("Toggle button is turned on 1st Adv i.e Fail/true");
			screenshots(driver,filepath);
			e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Toggle button is turned on 1st Adv","Fail",filepath);
			Thread.sleep(3000);
		}
		else if(countToggle.get(1).isEnabled()== false)
		{
			System.out.println("Toggle button is turned on 2nd Adv i.e Fail/false");
			screenshots(driver,filepath);
			e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Toggle button is turned on 2nd Adv","Fail",filepath);

		}
		else
		{
			System.out.println("Toggle button is turned off i.e Pass");
			screenshots(driver,filepath);
			e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Toggle button is turned off","Pass",filepath);
		}
		}
		catch(Exception e)
		{
			e.getMessage();
		}
	}
	
    
    /* chnages*/
    public void textboxEmpty(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String filepath)
        {
            try
            {
                if(driver.findElement(ele).isEnabled()==false)
                {
                    System.out.println("Save button is disabled");
                    screenshots(driver,filepath);
                    e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Save button is disabled","Pass",filepath);
                }
                else
                {
                    System.out.println("Save button is enabled");
                    screenshots(driver,filepath);
                    e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Save button is enabled","Fail",filepath);
                }
            }
     
            catch(Exception e)
            {
                e.getMessage();
            }
        }
     
        public void textboxNotEmpty(AppiumDriver driver,By ele,String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String filepath)
        {
            try
            {
                if(driver.findElement(ele).isEnabled()==true)
                {
                    System.out.println("Save button is enabled");
                    screenshots(driver,filepath);
                    e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Save button is enabled","Pass",filepath);
                }
                else
                {
                    System.out.println("Save button is disabled");
                    screenshots(driver,filepath);
                    e.writeExcelIOS(TC_ID,TC_Desc,TC_Steps,Exp_Res,"Save button is disabled","Fail",filepath);
                }
            }
     
            catch(Exception e)
            {
                e.getMessage();
            }
        }

}


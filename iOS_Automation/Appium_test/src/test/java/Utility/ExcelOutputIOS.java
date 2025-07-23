package Utility;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Date;

import org.apache.commons.io.IOUtils;
import org.apache.poi.common.usermodel.HyperlinkType;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFClientAnchor;
import org.apache.poi.xssf.usermodel.XSSFCreationHelper;
import org.apache.poi.xssf.usermodel.XSSFDrawing;
import org.apache.poi.xssf.usermodel.XSSFFont;
import org.apache.poi.xssf.usermodel.XSSFHyperlink;
import org.apache.poi.xssf.usermodel.XSSFPicture;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

public class ExcelOutputIOS {

	static int rowCounter=0;
	int row=0;
	
	
	String filepathIOS = System.getProperty("user.dir") + "//Excel/ReportIOS.xlsx";

	public void writeExcelIOS(String TC_ID,String TC_Desc,String TC_Steps,String Exp_Res,String Act_Res,String Status,String filepath) throws IOException
	{
		File file = new File(filepathIOS);
		FileInputStream inputStream = null;
		XSSFWorkbook workbook=null;
		XSSFSheet sheet1=null;


		if(file.exists())
		{
			inputStream=new FileInputStream(file);
			workbook=new XSSFWorkbook(inputStream);			
			sheet1=workbook.getSheet("IOS");	

		}
		else
		{
			workbook =new XSSFWorkbook();
			sheet1=workbook.createSheet("IOS");
		}

		//add picture data to this workbook.
		FileInputStream inputStream1 = new FileInputStream(filepath);
		byte[] bytes = IOUtils.toByteArray(inputStream1);
		int pic_id = workbook.addPicture(bytes, Workbook.PICTURE_TYPE_PNG);
		inputStream1.close();
		XSSFCreationHelper helper = workbook.getCreationHelper();
		XSSFDrawing drawing = sheet1.createDrawingPatriarch();
		XSSFClientAnchor my_anchor = helper.createClientAnchor();
		

		my_anchor.setCol1(7);
		my_anchor.setRow1(++row);  

		XSSFPicture my_picture = drawing.createPicture(my_anchor,pic_id );
		my_picture.resize(1.0,1.0);  
		
		XSSFRow row = sheet1.createRow(0);
		row.createCell(0).setCellValue("TC_NO");
		row.createCell(1).setCellValue("TC_ID");
		row.createCell(2).setCellValue("TC Description");
		row.createCell(3).setCellValue("TC Steps");
		row.createCell(4).setCellValue("Expected Result");
		row.createCell(5).setCellValue("Actual Result");
		row.createCell(6).setCellValue("Status");
		row.createCell(7).setCellValue("Screenshot"); 
		
	//	sheet1.autoSizeColumn(7); 
		
		

		FileOutputStream fileOut = new FileOutputStream(file);


		int i = rowCounter;
		rowCounter++;

		sheet1.createRow(i+1).createCell(0).setCellValue(i+1);
		sheet1.getRow(i+1).createCell(1).setCellValue(TC_ID);
		sheet1.getRow(i+1).createCell(2).setCellValue(TC_Desc);
		sheet1.getRow(i+1).createCell(3).setCellValue(TC_Steps);
		sheet1.getRow(i+1).createCell(4).setCellValue(Exp_Res);
		sheet1.getRow(i+1).createCell(5).setCellValue(Act_Res);
		sheet1.getRow(i+1).createCell(6).setCellValue(Status);
		
		
		workbook.write(fileOut);
		workbook.close();

	}

}




package Test;

public class StartServer {
	
	/*	public boolean checkIfServerIsRunning(int port)
	{
		boolean isServerRunning = false;
		ServerSocket serverSocket;
		try {
			serverSocket = new ServerSocket(port);
			serverSocket.close();
		} catch(IOException e)
		{
			// If control comes here, then it means that port is in use
			isServerRunning = true;
		} finally {
			serverSocket = null;
		}
		return isServerRunning;
	}

	public void startServer() {
	//	CommandLine cmd = new CommandLine("C:\\Program Files\\nodejs\\node.exe");
		CommandLine cmd = new CommandLine("/usr/local/bin/node");
	//	cmd.addArgument("C:\\Users\\gadhanan\\AppData\\Local\\Programs\\Appium Server GUI\\resources\\app\\node_modules\\appium\\build\\lib\\main.js");
		cmd.addArgument("/usr/local/bin/appium");
	//	cmd.addArgument("--base-path");
	//	cmd.addArgument("wd/hub");
		cmd.addArgument("--address");
		cmd.addArgument("127.0.0.1");
		cmd.addArgument("--port");
		cmd.addArgument("4723");
	//	cmd.addArgument("--base-path");
	//	cmd.addArgument("wd/hub");
	//	cmd.addArguments("--base-path","wd/hub");
		
		

		DefaultExecuteResultHandler handler = new DefaultExecuteResultHandler();
		DefaultExecutor executor = new DefaultExecutor();
		executor.setExitValue(1);
		try {
			executor.execute(cmd, handler);
			Thread.sleep(10000);
		} catch(IOException | InterruptedException e) {
			e.printStackTrace();
		}
	}

	public void stopServer() {
		Runtime runtime = Runtime.getRuntime();
		try {
			runtime.exec("taskkill /F /IM node");
		} catch(IOException e) {
			e.printStackTrace();
		}
	} */

}

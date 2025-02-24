public class FenceRepairing {

	public double calculateCost(String[] boards) {
		boolean[] fence;
		int n=0;
		for(int i=0;i<boards.length;i++){
			n+=boards[i].length();
		}
		fence=new boolean[n];
		int idx=0;
		for(int i=0;i<boards.length;i++){
			for(int j=0;j<boards[i].length();j++){
				if(boards[i].charAt(j)=='.'){
					fence[idx++]=true;
				}else{
					fence[idx++]=false;
				}
			}
		}
		double[] dp=new double[n+1];
		dp[0]=0;
		for(int i=1;i<=n;i++){
			dp[i]=9999999999.0;
			if(fence[i-1]){
				
				dp[i]=dp[i-1];
			}
			for (int j=0;j<i;j++)
		        dp[i]=Math.min(dp[i],dp[j]+Math.sqrt(i-j));

			
		}
		
		
		return dp[n];
	}

}

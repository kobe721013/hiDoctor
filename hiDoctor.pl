use IO::Socket::SSL qw();
use WWW::Mechanize qw();
use File::Path;
use Time::Piece ();
use Time::Seconds;
use Win32::Process;
use Win32;
use Cwd;


($s,$m,$h,$D,$M,,$y)=localtime(time);
my $nowDate = sprintf( "%04s%02s%02s", $y+1900,$M+1,$D);
#my $nowDate="20150915";
my $nowTime = sprintf( "%02s%02s%02s", $h,$m,$s);
my $logFileName = "$nowDate-$nowTime.html";
my $logAbsPath = cwd()."/Log/".$logFileName;
print "logPath($logAbsPath)\n";
open(append_file,">>$logAbsPath") or  "open file error" ;

#get date/time
my $dt = Time::Piece->strptime( $nowDate, '%Y%m%d');
$dt += ONE_DAY;
my $nextDate = $dt->strftime('%Y%m%d');
$dt += ONE_DAY*27;
my $watedDate = $dt->strftime('%Y%m%d');


print "now date/time:$nowDate\n";
print "next date/time:$nextDate\n";
print "wanted date/time:$watedDate\n";


#get patient config
my $file="./hiDoctor.txt";
open(FHD, "$file") || die "$!n"; 
my @all=<FHD>;
close(FHD);

print append_file "================= App start ==================<br>\n";
#SSL connect
my $mech = WWW::Mechanize->new(ssl_opts => {
    SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
    verify_hostname => 0, # this key is likely going to be removed in future LWP >6.04
});

#等待時間到，開始掛號
print "waitting date($nextDate) come!!!\n";
while (1) {
	# body...
	($s,$m,$h,$D,$M,,$y)=localtime(time); 
	my $nowDate = sprintf( "%04s%02s%02s", $y+1900,$M+1,$D);
	if($nowDate == $nextDate){
		print append_file "time up now($nowDate), next($nextDate), go~<br>\n";
		last;
	}
}

print "time'up, go~\n";
$origPdsect='null';
for($i=0; $i<=$#all; $i++){
	 my @para = split(',\t', @all[$i]);  

	 if(@para[0]=='#') {
	 	#print "disabled\n";
	 	next;
	 }
	 #print append_file "No."+$i+1+" config\n";
	 print append_file "0:@para[0]<br>\n"; #啟用
	 print append_file "1:@para[1]<br>\n"; #身份證ID
	 print append_file "2:@para[2]<br>\n"; #出生月 
	 print append_file "3:@para[3]<br>\n"; #出生日
	 print append_file "4:@para[4]<br>\n"; #科別代號
	 print append_file "5:@para[5]<br>\n"; #看診日期
	 print append_file "6:@para[6]<br>\n"; #上/下午
	 print append_file "7:@para[7]<br>\n"; #診別
	 
	 
	 if(@para[5]!= $watedDate) {
	 	print append_file "date(@para[5]) not equql wanted date($watedDate), skip~<br>\n";
	 	next;
	
	}
	if($origPdsect != @para[4]){
		print append_file "different pdsect<br>\n";
		#科別不同，從選擇科別頁面進去
		$mech->get("https://www6.vghtpe.gov.tw/opd/opd_inter/vgh_opda.htm");		
		$mech->submit_form(
		    with_fields => {
		    	pg => 'Oregi01d',
		    	back => 'vgh_opda.htm',
		    	svl => 'Y',
		    	pdsect => "@para[4]",#科別
		    	#pdsect => '012-112',#科別hardcode testing
		        Bnweek4 => '三週至第27天',
		    }
		);
	}
	$origPdsect = $para[4];	
	@result = $mech->submit_form(
	    with_fields => {	    	
	    	oregkey => "@para[5]@para[6]@para[7]",#醫生
	    	#oregkey => '2015101201201',#醫生,hardcode testing...
	        pid => "@para[1]",#PID
	        #pid => 'F125896017',#PID
	        pbirth_mm => "@para[2]",
	        pbirth_dd => "@para[3]",
	        #pbirth_mm => '10',#hardcode testing...
	        #pbirth_dd => '13',#hardcode testing...
	    }
	);
	$content = $mech->response->content;
	
	print append_file "finish content:$content<br>\n";	
	$status = $mech->response->message;        
    print append_file "msg:($status)<br>\n";
    $backresult = $mech->back();#finish, goto prePage
    
}

printf append_file "================= finish ==================<br>\n";
close(append_file);

print "IE open Result\n";
#IE open result
Win32::Process::Create(
		$ProcessObj,
		"C:\\Program Files\\Internet Explorer\\iexplore.exe",
		"iexplore $logAbsPath",
		0,
		NORMAL_PRIORITY_CLASS,
		"."
) || die ErrorReport();
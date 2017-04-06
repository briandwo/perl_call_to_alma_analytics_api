#!/usr/bin/perl
#
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;

#My api_key defined in the Alma Developer's Network
$api_key = "YOUR_API_KEY_HERE";

#ExLibris API call
$rpt_base = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/analytics/reports";
$token_base = "?token=";

#$rpt_path = "?path=%2Fshared%2FBoston College%2FReports%2FBib%2FE-Books from YBPDDA";
$rpt_path = "?path=%2Fshared%2FBoston College%2FReports%2FDatawarehouse%2FPullItem";
#$rpt_path = "?path=%2Fshared%2FBoston College%2FReports%2FDatawarehouse%2FGetVendors";

$rpt_filter_begin = "&filter=%3Csawx%3Aexpr%20xsi%3Atype%3D%22sawx%3Alogical%22%20op%3D%22beginsWith%22%20xmlns%3Asaw%3D%22com.siebel.analytics.web%2Freport%2Fv1.1%22%20%0Axmlns%3Asawx%3D%22com.siebel.analytics.web%2Fexpression%2Fv1.1%22%20xmlns%3Axsi%3D%22http%3A%2F%2Fwww.w3.org%2F2001%2FXMLSchema-instance%22%20%0Axmlns%3Axsd%3D%22http%3A%2F%2Fwww.w3.org%2F2001%2FXMLSchema%22%3E%0A%3Csawx%3Aexpr%20xsi%3Atype%3D%22sawx%3AsqlExpression%22%3E%22Holding%20Details%22.%22Permanent%20LC%20Classification%20Code%22%3C%2Fsawx%3Aexpr%3E%0A%3Csawx%3Aexpr%20xsi%3Atype%3D%22xsd%3Astring%22%3E";

$rpt_filter_end = "%3C%2Fsawx%3Aexpr%3E%0A%3C%2Fsawx%3Aexpr%3E";

$rpt_args = "R";

$rpt_filter = sprintf("%s%s%s", $rpt_filter_begin, $rpt_args, $rpt_filter_end);

$have_key = 0; #Only get a resumption token once. Need to re-use it

$rpt_limit = "&limit=1000"; #Override row return from 25 to 1000
$key_add = "&apikey=";

($my_day, $my_mon, $my_year) = (localtime) [3,4,5];
$pt_day = sprintf("%02d", $my_day);
$my_year += 1900;
$my_mon += 1;
$my_date = sprintf("%s%02d%02d", $my_year, $my_mon, $my_day);

#Open output file
$out_file = sprintf("%s%s%s", "ONL_NL_items_", $my_date, ".csv");
$ret = open(OUT_FILE, ">$out_file");
if ($ret < 1)
{
     die ("Cannot open file $out_file");
}

$line = sprintf("%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", "Title", "|", "Author", "|", "Publisher", "|", "Pub Date", "|", "MMS ID", "|", "Library", "|", "Location", "|", "Call Number", "|", "Barcode", "|", "Description", "|", "Material Type");
print OUT_FILE ("$line\n");


#Open API calling agent
$api_call = LWP::UserAgent->new(
    ssl_opts => { verify_hostname => 0 },
    cookie_jar => {},
    );


#$rpt_url = sprintf("%s%s%s%s", $rpt_base, $rpt_path, $key_add, $api_key);     
$rpt_url = sprintf("%s%s%s%s%s%s", $rpt_base, $rpt_path, $rpt_limit, $key_add, $api_key, $rpt_filter);     

$rpt_resp = $api_call->get($rpt_url);
$rpt_xml = XMLin($rpt_resp->content, ForceArray=>1, KeyAttr=>undef);
print Dumper($rpt_xml);

$done = 0;

while (!$done)
{
     #Determine how many rows were returned from the API
     @ret_rows  = @{$rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}};
     $row_count = @ret_rows;

     #Grab the returned data. This is not in the order that the report retrieves it. Opened a SF case for this.
     for ($i = 0; $i < $row_count; $i++)
     {
          $lib = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column9}->[0];
          $pub_yr = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column3}->[0];
          $title = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column5}->[0];
          $pub = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column4}->[0];
          $barcode = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column11}->[0];
          $mms_id = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column2}->[0];
          $call_no = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column6}->[0];
          $lc_class_no = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column8}->[0];
          $author = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column1}->[0];
          $mat_type = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column13}->[0];
          $desc = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column12}->[0];
          $loc = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column10}->[0];
          $lc_class_code = $rpt_xml->{QueryResult}->[0]->{ResultXml}->[0]->{rowset}->[0]->{Row}->[$i]->{Column7}->[0];

          $line = sprintf("%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", $title, "|", $author, "|", $pub, "|", $pub_yr, "|", $mms_id, "|", $lib, "|", $loc, "|", $call_no, "|", $barcode, "|", $desc, "|", $mat_type);
          print OUT_FILE ("$line\n");
     }

     #See if API returned all of the data. If not, go get more.
     $complete = $rpt_xml->{QueryResult}->[0]->{IsFinished}->[0];
     if ($complete eq 'false') #All of the data was not returned in the first call
     {
          #Check to see if have the resumption token. This is only returned once and same token is used over and over again
          if (!$have_key)
          {
               $resume_key = $rpt_xml->{QueryResult}->[0]->{ResumptionToken}->[0];
               $have_key = 1; #Flag that we have the resumption token now
          }

          #To continue replace report path with resumption token
          $rpt_url = sprintf("%s%s%s%s%s%s%s", $rpt_base, $token_base, $resume_key, $rpt_limit, $key_add, $api_key, $rpt_filter);     

          $rpt_resp = $api_call->get($rpt_url);
          $rpt_xml = XMLin($rpt_resp->content, ForceArray=>1, KeyAttr=>undef);
          print Dumper($rpt_xml);
     }
     else
     {
          $done = 1;
     }
}

close (OUT_FILE);

exit;


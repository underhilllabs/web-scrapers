# chunk = "TenureNo.NameLobbyist1288KENT W. GLASSMAN6960 W. Princeton Ave., Denver, CO 80235; 720-220-921105/11/2004Registered:KentGlassman@MSN.com1272RICHARD L. GONZALES2505 18th Street, Denver, CO 80211; 303-433-838311/25/2003Registered:Richard.Gonzales@UnitedWayDenver.org1161MICKI M. HACKENBERGER1005 17th Street, Suite 200, Denver, CO 80202; 303-896-426909/03/1997Registered:[not supplied]1283LYNEA C. HANSEN950 17th Street, Suite 1750, Denver, CO 80202; 303-534-439902/17/2004Registered:Lynea@TheKenneyGroup.com1252HAYS, HAYS AND WILSON, INC.1301 Pennsylvania Street, Suite #900, Denver, CO 80203; 303-860-161607/08/2003Registered:HHW@HaysHaysWilson.com1042HOLME ROBERTS & OWEN LLP1700 Lincoln Street, Suite 4100, Denver, CO 80203; 303-861-700006/18/1992Registered:Debra.Heglin@HRO.com1168KATHRYN WORKS AND ASSOCIATES, INC.1625 Broadway, Suite 805, Denver, CO 80202; 303-861-448203/24/1998Registered:ScottMeiklejohn@Comcast.net1309BENJAMIN W. KELLY1999 Broadway, Suite 4190, Denver, CO 80202; 303-534-439906/15/2005Registered:Ben@TheKenneyGroup.com1151DAVID W. KENNEY1999 Broadway, Suite 4190, Denver, CO 80202; 303-534-439911/15/1996Registered:David@TheKenneyGroup.com1281KENNEY GROUP, INC., THE1999 Broadway, Suite 4190, Denver, CO 80202; 303-534-439902/17/2004Registered:David@TheKenneyGroup.com1241LAURA  LIPICH1780 South Bellaire Street - Suite 402, Denver, CO 80222; 303-756-616310/11/2002Registered:Lesli@ctepa.org1336LOMBARD & CLAYTON, INC.10174 Meade Ct., Westminster, CO 80031; 303-884-911308/22/2007Registered:Tony@LombardClayton.com1343LAUREN W. MARTENS2525 W. Alameda, Denver, CO 80219; 303-727-800504/27/2009Registered:LMartens@SEIU105.org1312CHRIS JIM MARTINEZ8363 E. Mansfield Ave, Denver, CO 80237; 303-880-670107/21/2005Registered:CJimM@Comcast.net1197SARAH F. MAUK1600 Stout Street, Suite 1770, Denver, CO 80202; 303-892-585801/20/2000Registered:SFHillyard@aol.com"

# # puts chunk.split("Registered")[0] 
# # chunk.match(/(\d{3}-\d{3}-\d{4})/) do |m|
# #   puts m
# # end

# # email_addresses = chunk.scan(/(\S*?@\S*?\.\S*?)/m)
# # phone_numbers = chunk.scan(/(\d{3}-\d{3}-\d{4})/m)
# # emails = chunk.scan(/:(\S*?@\S*?\.\S{3}|\[not supplied\])/)
# # ids = chunk.scan(/(\d{4})\w/)

# # # works except have to split name from address
# # lobbyists = chunk.scan(/(\d{4})\w(*?)\; (\d{3}-\d{3}-\d{4}).*?Registered:(\S*?@\S*?\.\S{2,3}|\[not supplied\])/)

# # # This will choke on PO Box for address
# # lobbyists = chunk.scan(/(\d{4})(.*?)(\d.*?)\; (\d{3}-\d{3}-\d{4}).*?Registered:(\S*?@\S*?\.\w{2,3}|\[not supplied\])/)

#################################################################
# Extract text from a PDF file
# This scraper takes about 2 minutes to run and no output
# appears until the end.
#################################################################
# This scraper uses the pdf-reader gem.
# Documentation is at https://github.com/yob/pdf-reader#readme
# If you have problems you can ask for help at http://groups.google.com/group/pdf-reader
require 'pdf-reader'   
require 'open-uri'

##########  This section contains the callback code that processes the PDF file contents  ######
class PageTextReceiver
  attr_accessor :content, :page_counter
  def initialize
    @content = []
    @page_counter = 0
  end
  # Called when page parsing starts
  def begin_page(arg = nil)
    @page_counter += 1
    @content << ""
  end
  # record text that is drawn on the page
  def show_text(string, *params)
    @content.last << string
  end
  # there's a few text callbacks, so make sure we process them all
  alias :super_show_text :show_text
  alias :move_to_next_line_and_show_text :show_text
  alias :set_spacing_next_line_show_text :show_text
  # this final text callback takes slightly different arguments
  def show_text_with_positioning(*params)
    params = params.first
    params.each { |str| show_text(str) if str.kind_of?(String)}
  end
end
################  End of TextReceiver #############################

# If you don't have two minutes to wait you might prefer this
# smaller pdf
# pdf = open('http://www.hmrc.gov.uk/factsheets/import-export.pdf')
# pdf = open('http://www.madingley.org/uploaded/Hansard_08.07.2010.pdf') 
# pdf = open('http://dl.dropbox.com/u/6928078/CLEI_2008_002.pdf')
# pdf = open('http://www.denvergov.org/Portals/98/documents/Lobbyists/Public%20Record/CC_Active_Lobbyists.pdf')
pdf =open('http://bigox.denvertech.org/CC_Active_Lobbyists.pdf')
#######  Instantiate the receiver and the reader
receiver = PageTextReceiver.new
pdf_reader = PDF::Reader.new 
#######  Now you just need to make the call to parse...
pdf_reader.parse(pdf, receiver)
#######  ...and do whatever you want with the text.  
#######  This just outputs it.

big_list = []
count = 0
receiver.content.each do |r| 
  #puts r.strip
  
  # each page starts with header: TenureNo....
  # so split that off and grab the rest
  pages = r.split(/TenureNo\.NameLobbyist/)
  #pages[0] is the header, ignore that
  page = pages[1]
  # split the lobbyists up by email address
  #lobbyists = page.split(/\.com|\.net|\.org|\[not suppled\]/)
  # Currently this will choke on PO Boxes
  lobbyists = page.scan(/(\d{4})(.*?)(\d.*?)\; (\d{3}-\d{3}-\d{4}).*?Registered:(\S*?@\S*?\.\w{2,3}|\[not supplied\])/)
  #puts lobbyists
  lobbyists.each do |l|
    ScraperWiki.save_sqlite(unique_keys=["id"], data={"id"=>l[0], "name"=>l[1], "address"=>l[2], "phone"=>l[3], "email"=>l[4]})
    puts "saved #{l[1]}"   
  end
  count += lobbyists.length
end

puts "Found #{count} active lobbyists."

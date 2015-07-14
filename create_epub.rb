#!/usr/local/bin/ruby
require 'fileutils'
require 'open3'

# Create Directories
Dir.mkdir('META-INF') unless File.exists?('META-INF')
Dir.mkdir('OEBPS') unless File.exists?('OEBPS')
Dir.mkdir('OEBPS/text') unless File.exists?('OEBPS/text')
#Dir.mkdir('OEBPS/images') unless File.exists?('OEBPS/images')

# Create Standard Files
mimetype = File.new('mimetype','w')
mimetype.print 'application/epub+zip'
mimetype.close
container = File.new('META-INF/container.xml','w')
container.puts '<?xml version="1.0"?>'
container.puts '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
container.puts '  <rootfiles>'
container.puts '    <rootfile full-path="OEBPS/content.opf"'
container.puts '     media-type="application/oebps-package+xml" />'
container.puts '  </rootfiles>'
container.puts '</container>'
container.close

# Get Chapter Names
list = File.readlines('src/toc.txt')
names = []
File.read('src/toc.txt').each_line do |line|
  if line.include? '.'
    title = line.split('.')
    names.push [title[0],title[1][1,title[1].length-2].gsub('&','&#38;')]
  elsif line.include? ':'
    title = line.split(':')
    names.push [title[0],title[1][1,title[1].length-2]]
  end
end

# Create content.opf
id = '4663456854457'
content = File.new('OEBPS/content.opf','w')
content.puts '<?xml version=\'1.0\' encoding=\'utf-8\'?>
<package xmlns="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/" unique-identifier="bookid" version="2.0">
    <metadata>
        <dc:title>Tensei Shitara Slime datta ken</dc:title>
        <dc:creator>Fuse</dc:creator>
        <dc:identifier id="bookid">urn:uuid:'+id+'</dc:identifier>
        <dc:language>en</dc:language>
    </metadata>
    <manifest>
        <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />
        <item id="cover" href="text/cover.xhtml" media-type="application/xhtml+xml" />
        <item id="content" href="text/content.xhtml" media-type="application/xhtml+xml" />
        <item id="credits" href="text/credits.xhtml" media-type="application/xhtml+xml" />
        <item id="prologue" href="text/prologue.xhtml" media-type="application/xhtml+xml" />'
names.each do |x,y|
  if x != 'Extra'
    content.puts ' '*8+'<item id="ch'+x+'" href="text/chapter'+x+'.xhtml" media-type="application/xhtml+xml" />'
  else
    content.puts ' '*8+'<item id="ex'+y.gsub(/\s+/,'')+'" href="text/extra'+y.gsub(/\s+/,'')+'.xhtml" media-type="application/xhtml+xml" />'
  end
end
content.puts '        <item id="css" href="stylesheet.css" media-type="text/css" />
    </manifest>
    <spine toc="ncx">
        <itemref idref="cover" />
        <itemref idref="credits" />
        <itemref idref="content" />
        <itemref idref="prologue" />'
names.each do |x,y|
  if x != 'Extra'
    content.puts ' '*8+'<itemref idref="ch'+x+'" />'
  else
    content.puts ' '*8+'<itemref idref="ex'+y.gsub(/\s+/,'')+'" />'
  end
end
content.puts '    </spine>
    <guide>
        <reference href="text/cover.xhtml" type="cover" title="Cover" />
    </guide>
</package>'
content.close

# Create toc
toc = File.new('OEBPS/toc.ncx','w')
toc.puts '<?xml version=\'1.0\' encoding=\'utf-8\'?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
    <head>
        <meta name="dtb:uid" content="urn:uuid:'+id+'" />
        <meta name="dtb:depth" content="1" />
        <meta name="dtb:totalPageCount" content="0" />
        <meta name="dtb:maxPageNumber" content="0" />
    </head>
    <docTitle>
        <text>Tensei Shitara Slime datta ken</text>
    </docTitle>
    <navMap>
        <navPoint id="navpoint-1" playOrder="1">
            <navLabel><text>Regarding Reincarnated to Slime</text></navLabel>
            <content src="text/cover.xhtml" />
        </navPoint>
        <navPoint id="navpoint-2" playOrder="2">
            <navLabel><text>CREDITS</text></navLabel>
            <content src="text/credits.xhtml" />
        </navPoint>
        <navPoint id="navpoint-3" playOrder="3">
            <navLabel><text>TABLE OF CONTENTS</text></navLabel>
            <content src="text/content.xhtml" />
        </navPoint>
        <navPoint id="navpoint-4" playOrder="4">
            <navLabel><text>Prologue - Death and Reincarnation</text></navLabel>
            <content src="text/prologue.xhtml" />
        </navPoint>'
count = 5
names.each do |x,y|
  if x != 'Extra'
    title = y.gsub('&','&#38;')
    toc.puts ' '*8+'<navPoint id="navpoint-'+count.to_s+'" playOrder="'+count.to_s+'">'
    toc.puts ' '*12+'<navLabel><text>Chapter '+x+' - '+y+'</text></navLabel>'
    toc.puts ' '*12+'<content src="text/chapter'+x+'.xhtml" />'
    toc.puts ' '*8+'</navPoint>'
    count+=1
  else
    toc.puts ' '*8+'<navPoint id="navpoint-'+count.to_s+'" playOrder="'+count.to_s+'">'
    toc.puts ' '*12+'<navLabel><text>'+x+' - '+y+'</text></navLabel>'
    toc.puts ' '*12+'<content src="text/extra'+y.gsub(/\s+/,'')+'.xhtml" />'
    toc.puts ' '*8+'</navPoint>'
    count+=1
  end
end
toc.puts '    </navMap>
</ncx>'
toc.close

# Create Stylesheet
f = File.new('OEBPS/stylesheet.css','w')
f.puts File.read('src/stylesheet.css')
f.close

#Create Cover
f = File.new('OEBPS/text/cover.xhtml','w')
f.puts File.read('src/cover.xhtml')
f.close

#Create Credits
f = File.new('OEBPS/text/credits.xhtml','w')
f.puts File.read('src/credits.xhtml')
f.close

# Create Table of Contents
toc = File.new('OEBPS/text/content.xhtml','w')
toc.puts '<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Table of Contents</title>
        <link type="text/css" rel="stylesheet" media="all" href="../stylesheet.css" />
    </head>
    <body>
        <div>
            <h3 style="font-weight:normal;text-align:center;">Tensei Shitara Slime datta ken</h3>
            <br />
            <div>
                <h4>Prologue</h4>
                <p><a href="prologue.xhtml">Death and Reincarnation</a></p>'
skip = 2
list.each do |s|
  if skip < 1
    if s.include? '.'
      title = s.split('.')
      title[1].gsub!('&','&#38;')
      toc.puts ' '*16+'<p><a href="chapter'+title[0]+'.xhtml">CHAPTER '+title[0]+' - '+title[1][1,title[1].length-2]+'</a></p>'
    elsif s.include? ':'
      title = s.split(':')
     toc.puts ' '*16+'<p><a href="extra'+title[1].gsub(/\s+/,'')+'.xhtml">EXTRA - '+title[1][1,title[1].length-2]+'</a></p>'
    else
      toc.puts ' '*16+'<br />'
      toc.puts ' '*16+'<h4>'+s[0,s.length-1]+'</h4>'
    end
  else
    skip-=1
  end
end
toc.puts "            </div>\n        </div>\n    </body>\n</html>"
toc.close

# Create chapters
f = File.new('OEBPS/text/prologue.xhtml','w')
f.puts '<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Prologue</title>
        <link type="text/css" rel="stylesheet" media="all" href="../stylesheet.css" />
    </head>
    <body>
        <div>'
f.puts File.read('src/prologue.txt')
f.print '        </div>
    </body>
</html>'
f.close

names.each do |x,y|
  if File.file?('src/chapter'+x+'.txt') or File.file?('src/chapterextra'+y.gsub(' ','')+'.txt')
    t = ''
    if x != 'Extra'
      t = File.new('OEBPS/text/chapter'+x+'.xhtml','w')
      t.puts '<html xmlns="http://www.w3.org/1999/xhtml">'
      t.puts "    <head>\n        <title>Chapter "+x+"</title>"
    else
      t = File.new('OEBPS/text/extra'+y.gsub(' ','')+'.xhtml','w')
      t.puts '<html xmlns="http://www.w3.org/1999/xhtml">'
      t.puts "    <head>\n        <title>Extra - "+y+"</title>"
    end
    t.puts '        <link type="text/css" rel="stylesheet" media="all" href="../stylesheet.css" />'
    t.puts "    </head>\n<body>\n        <div>"
    if x != 'Extra'
      t.puts File.read('src/chapter'+x+'.txt')
    else
      t.puts File.read('src/chapterextra'+y.gsub(' ','')+'.txt')
    end
    t.print "        </div>\n    </body>\n</html>"
    t.close
  end
end

# Zip Files
Open3.popen3('zip -X0 TenseiShitaraSlimeDattaKen.epub mimetype') do |stdin,stdout,stderr,wait_thr|
  puts stdout.read
end
Open3.popen3('zip -X9Dr TenseiShitaraSlimeDattaKen.epub META-INF OEBPS') do |stdin,stdout,stderr,wait_thr|
  puts stdout.read
end

#!/usr/local/bin/ruby
require 'erb'
require 'fileutils'
require 'open3'

def render_file_with_erb(file)
  rhtml = File.read file
  unless rhtml.nil?
    erb = ERB.new(rhtml)
    erb.result(binding)
  else
    raise "Could not open " + file
  end
end

def create(input)
  @arc = input
  @nameOfArc = ''
  @id = '2073490153'+@arc
  # Create Directories ########################################
  Dir.mkdir('META-INF') unless File.exists?('META-INF')
  Dir.mkdir('OEBPS') unless File.exists?('OEBPS')
  Dir.mkdir('OEBPS/text') unless File.exists?('OEBPS/text')
  Dir.mkdir('OEBPS/images') unless File.exists?('OEBPS/images')
  # Copy Files ################################################
  FileUtils.cp('src/mimetype','mimetype')
  FileUtils.cp('src/container.xml','META-INF/container.xml')
  FileUtils.cp('src/cover'+@arc+'.xhtml','OEBPS/text/cover'+@arc+'.xhtml')
  FileUtils.cp('src/credits'+@arc+'.xhtml','OEBPS/text/credits'+@arc+'.xhtml')
  FileUtils.cp('src/stylesheet.css','OEBPS/stylesheet.css')
  # Copy Images ###############################################
  images = Dir['src/images/v'+@arc+'-*.jpg']
  images.each{ |filename| FileUtils.cp(filename,"OEBPS/images/#{File.basename(filename)}") }
  # Get Chapter Names #########################################
  names = []
  File.read('src/toc'+@arc+'.txt').each_line do |line|
    if line.include? '.'
      title = line.split('.')
      names.push [title[0],title[1].strip.gsub('&','&#38;')]
    elsif line.include? ':'
      title = line.split(':')
      names.push [title[0],title[1].strip]
    else
      @nameOfArc = line.strip
    end
  end
  # Create content.opf ########################################
  @files, @entries = '', ''
  f = File.new('OEBPS/content.opf','w')
  names.each do |x,y|
    if x == 'Prologue'
      @files << ' '*8+'<item id="prologue" href="text/prologue.xhtml" media-type="application/xhtml+xml" />'+"\n"
    elsif x == 'Extra'
      @files << ' '*8+'<item id="ex'+y.gsub(/\s+/,'')+'" href="text/extra'+y.gsub(/\s+/,'')+'.xhtml" media-type="application/xhtml+xml" />'+"\n"
    else
      @files << ' '*8+'<item id="ch'+x+'" href="text/chapter'+x+'.xhtml" media-type="application/xhtml+xml" />'+"\n"
    end
  end
  images.each do |filename|
    if File.basename(filename,'.jpg').include? "cover"
      @files << ' '*8+'<item id="cover" href="images/'+File.basename(filename)+'" media-type="image/jpeg" />'+"\n"
    else
      @files << ' '*8+'<item id="'+File.basename(filename,'.jpg')+'" href="images/'+File.basename(filename)+'" media-type="image/jpeg" />'+"\n"
    end
    
  end
  names.each do |x,y|
    if x == 'Prologue'
      @entries << ' '*8+'<itemref idref="prologue" />'+"\n"
    elsif x == 'Extra'
      @entries << ' '*8+'<itemref idref="ex'+y.gsub(/\s+/,'')+'" />'+"\n"
    else
      @entries << ' '*8+'<itemref idref="ch'+x+'" />'+"\n"
    end
  end
  f.print render_file_with_erb('content.opf.erb')
  f.close
  # Create toc file ###########################################
  @toc = ''
  f = File.new('OEBPS/toc.ncx','w')
  count = 4
  names.each do |x,y|
    @toc << ' '*8+'<navPoint id="navpoint-'+count.to_s+'" playOrder="'+count.to_s+'">'+"\n"
    if x == 'Prologue'
      @toc << ' '*12+'<navLabel><text>'+x+' - '+y+'</text></navLabel>'+"\n"
      @toc << ' '*12+'<content src="text/prologue.xhtml" />'+"\n"
    elsif x == 'Extra'
      @toc << ' '*12+'<navLabel><text>'+x+' - '+y+'</text></navLabel>'+"\n"
      @toc << ' '*12+'<content src="text/extra'+y.gsub(/\s+/,'')+'.xhtml" />'+"\n"
    else
      @toc << ' '*12+'<navLabel><text>Chapter '+x+' - '+y+'</text></navLabel>'+"\n"
      @toc << ' '*12+'<content src="text/chapter'+x+'.xhtml" />'+"\n"
    end
    count+=1
    @toc << ' '*8+'</navPoint>'+"\n"
  end
  f.print render_file_with_erb('toc.ncx.erb')
  f.close
  # Create Table of Contents ##################################
  @index = ''
  f = File.new('OEBPS/text/content.xhtml','w')
  names.each do |x,y|
    if x == 'Prologue'
      @index << ' '*16+'<p><a href="prologue.xhtml">PROLOGUE - '+y+'</a></p>'+"\n"
    elsif x == 'Extra'
      @index << ' '*16+'<p><a href="extra'+y.gsub(/\s+/,'')+'.xhtml">EXTRA - '+y+'</a></p>'+"\n"
    else
      @index << ' '*16+'<p><a href="chapter'+x+'.xhtml">CHAPTER '+x+' - '+y+'</a></p>'+"\n"
    end
  end
  f.print render_file_with_erb('content.xhtml.erb')
  f.close
  # Create chapters ###########################################
  names.each do |x,y|
    @title, @body, f  = '', '', ''
    if x == 'Prologue'
      f = File.new('OEBPS/text/prologue.xhtml','w')
      @title = 'Prologue'
      @body = File.read('src/text/prologue.txt') if File.file?('src/text/prologue.txt')
    elsif x == 'Extra'
      f = File.new('OEBPS/text/extra'+y.gsub(/\s+/,'')+'.xhtml','w')
      @title = 'Extra - '+y
      @body = File.read('src/text/chapterextra'+y.gsub(/\s+/,'')+'.txt') if File.file?('src/text/chapterextra'+y.gsub(/\s+/,'')+'.txt')
    else
      f = File.new('OEBPS/text/chapter'+x+'.xhtml','w')
      @title = 'Chapter '+x
      @body = File.read('src/text/chapter'+x+'.txt') if File.file?('src/text/chapter'+x+'.txt')
    end
    f.print render_file_with_erb('chapter.xhtml.erb')
    f.close
  end
  # Delete and Zip Files #mT ##################################
  File.delete('OEBPS/images/Thumbs.db') if File.file?('OEBPS/images/Thumbs.db')
  File.delete('TenseiShitaraSlimeDattaKen'+@arc+'.epub') if File.file?('TenseiShitaraSlimeDattaKen'+@arc+'.epub')
  Open3.popen3('zip -X0mT TenseiShitaraSlimeDattaKen'+@arc+'.epub mimetype'){ |stdin,stdout,stderr,wait_thr| puts stdout.read }
  Open3.popen3('zip -X9DrmT TenseiShitaraSlimeDattaKen'+@arc+'.epub META-INF OEBPS'){ |stdin,stdout,stderr,wait_thr| puts stdout.read }
end

create '01'
create '02'

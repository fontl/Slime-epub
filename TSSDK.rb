#!/usr/local/bin/ruby
require 'erb'
require 'fileutils'
require 'open3'

def render_file_with_erb(file)
  rhtml = File.read file
  ERB.new(rhtml).result(binding) unless rhtml.nil?
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
  FileUtils.cp('tssdk/mimetype','mimetype')
  FileUtils.cp('tssdk/container.xml','META-INF/container.xml')
  FileUtils.cp('tssdk/stylesheet.css','OEBPS/stylesheet.css')
  # Copy Images ###############################################
  images = Dir['tssdk/images/v'+@arc+'-*.jpg']
  images.each{ |filename| FileUtils.cp(filename,"OEBPS/images/#{File.basename(filename)}") }
  # Get Chapter Names #########################################
  names = []
  File.read('tssdk/toc'+@arc+'.txt').each_line do |line|
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
  @files, @entries, @ill = '', '', ''
  # Create illustration page and entries ######################
  Dir['tssdk/arc'+@arc+'/illustration'+@arc+'-*.txt'].each do |filename|
    @files << ' '*8+'<item id="'+File.basename(filename,'.txt')+'" href="text/'+File.basename(filename,'.txt')+'.xhtml" media-type="application/xhtml+xml" />'+"\n"
    @ill << '<itemref idref="'+File.basename(filename,'.txt')+'" />'+"\n"
    @pic = File.read(filename)
    f = File.new("OEBPS/text/#{File.basename(filename,'.txt')}.xhtml",'w')
    f.print render_file_with_erb('tssdk/illustration.xhtml.erb')
    f.close
  end
  names.each do |x,y|
    if x == 'Prologue'
      @files << ' '*8+'<item id="prologue" href="text/prologue.xhtml" media-type="application/xhtml+xml" />'+"\n"
      @entries << ' '*8+'<itemref idref="prologue" />'+"\n"
    elsif x == 'Extra'
      @files << ' '*8+'<item id="ex'+y.gsub(/\s+/,'')+'" href="text/extra'+y.gsub(/\s+/,'')+'.xhtml" media-type="application/xhtml+xml" />'+"\n"
      @entries << ' '*8+'<itemref idref="ex'+y.gsub(/\s+/,'')+'" />'+"\n"
    else
      @files << ' '*8+'<item id="ch'+x+'" href="text/chapter'+x+'.xhtml" media-type="application/xhtml+xml" />'+"\n"
      @entries << ' '*8+'<itemref idref="ch'+x+'" />'+"\n"
    end
  end
  if images.any?
    images.each do |filename|
      if File.basename(filename,'.jpg').include? "cover"
        @files << ' '*8+'<item id="cover" href="images/'+File.basename(filename)+'" media-type="image/jpeg" />'+"\n"
      else
        @files << ' '*8+'<item id="'+File.basename(filename,'.jpg')+'" href="images/'+File.basename(filename)+'" media-type="image/jpeg" />'+"\n"
      end
    end
  end
  f = File.new('OEBPS/content.opf','w')
  f.print render_file_with_erb('tssdk/content.opf.erb')
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
  f.print render_file_with_erb('tssdk/toc.ncx.erb')
  f.close
  # Create cover page #########################################
  @cover = File.read('tssdk/arc'+@arc+'/cover.txt') if File.file?('tssdk/arc'+@arc+'/cover.txt')
  f = File.new('OEBPS/text/cover.xhtml','w')
  f.print render_file_with_erb('tssdk/cover.xhtml.erb')
  f.close
  # Create credit page ########################################
  @credits = File.read('tssdk/arc'+@arc+'/credits'+@arc+'.txt') if File.file?('tssdk/arc'+@arc+'/credits'+@arc+'.txt')
  f = File.new('OEBPS/text/credits.xhtml','w')
  f.print render_file_with_erb('tssdk/credits.xhtml.erb')
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
  f.print render_file_with_erb('tssdk/content.xhtml.erb')
  f.close
  # Create chapters ###########################################
  names.each do |x,y|
    @title, @body, f  = '', '', ''
    if x == 'Prologue'
      @title = 'Prologue'
      @body = File.read('tssdk/arc'+@arc+'/prologue.txt') if File.file?('tssdk/arc'+@arc+'/prologue.txt')
      f = File.new('OEBPS/text/prologue.xhtml','w')
    elsif x == 'Extra'
      @title = 'Extra - '+y
      @body = File.read('tssdk/arc'+@arc+'/chapterextra'+y.gsub(/\s+/,'')+'.txt') if File.file?('tssdk/arc'+@arc+'/chapterextra'+y.gsub(/\s+/,'')+'.txt')
      f = File.new('OEBPS/text/extra'+y.gsub(/\s+/,'')+'.xhtml','w')
    else
      @title = 'Chapter '+x
      @body = File.read('tssdk/arc'+@arc+'/chapter'+x+'.txt') if File.file?('tssdk/arc'+@arc+'/chapter'+x+'.txt')
      f = File.new('OEBPS/text/chapter'+x+'.xhtml','w')
    end
    f.print render_file_with_erb('tssdk/chapter.xhtml.erb')
    f.close
  end
  # Delete and Zip Files #mT ##################################
  File.delete('OEBPS/images/Thumbs.db') if File.file?('OEBPS/images/Thumbs.db')
  File.delete('Tensei_Shitara_Slime_Datta_Ken-'+@arc+'.epub') if File.file?('Tensei_Shitara_Slime_Datta_Ken-'+@arc+'.epub')
  Open3.popen3('zip -X0mT Tensei_Shitara_Slime_Datta_Ken-'+@arc+'.epub mimetype'){ |stdin,stdout,stderr,wait_thr| puts stdout.read }
  Open3.popen3('zip -X9DrmT Tensei_Shitara_Slime_Datta_Ken-'+@arc+'.epub META-INF OEBPS'){ |stdin,stdout,stderr,wait_thr| puts stdout.read }
  FileUtils.remove_dir('OEBPS')
  FileUtils.remove_dir('META-INF')
  sleep 0.3
end

ARGV.each do |arg|
  create arg
end
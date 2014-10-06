module Timer
  @@t = []


  def self.start(text)
    Timer.output text
    @@t.map { |t| t[1] = true }
    @@t << [Time.now,false]
  end

  def self.stop(text=nil)
    t = @@t.pop
    if t[1]
      puts ' '
      print '   '*@@t.size
      print '-> '
    end
    print text if text
    print ' in ' if text
    print (1000 * (Time.now - t[0])).round
    print 'ms'
  end

  def self.output(text)
    print "\n"
    print '   '*@@t.size
    print "#{text}... "
  end

  def self.time(text)
    Timer.start text
    yield
    Timer.stop
  end
end
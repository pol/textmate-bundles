require 'enumerator' # each_slice
require 'rubygems'
require 'builder'

# These are language constructs rather than functions, so don't appear in the generated list
ConstructFunctions = {
  'eval'  => ['(string $code_str)', 'Evaluate a string as PHP code'],
  'echo'  => ['string $arg1 [, string $...]', 'Output one or more strings'],
  'print' => ['string $arg', 'Output a string'],
  'empty' => ['(mixed $var)', 'Determine whether a variable is empty'],
  'isset' => ['(mixed $var [, mixed $var [, $...]])', 'Determine whether a variable is set'],
  'unset' => ['(mixed $var [, mixed $var [, $...]])', 'Unset a given variable'],
  'list'  => ['(mixed $varname, mixed $...)', 'Assign variables as if they were an array'],
  'array' => ['([mixed $...])', 'Create an array']
}

if ARGV.size == 0
  puts "Usage: generate.rb functions_list.txt"
  puts "Run genfuncsummary.php (available on PHP CVS) to get functions_list.txt"
  exit 1
end

functions_file = ARGV.join(' ')

#  process_list
#  Created by Allan Odgaard on 2005-11-28.
#  http://macromates.com/svn/Bundles/trunk/Bundles/Objective-C.tmbundle/Support/list_to_regexp.rb
#
#  Read list and output a compact regexp
#  which will match any of the elements in the list
#  Modified by Ciarån Walsh to accept a plain string array
def process_list(list)
  buckets = { }
  optional = false

  list.map! { |term| term.unpack('C*') }

  list.each do |str|
    if str.empty? then
      optional = true
    else
      ch = str.shift
      buckets[ch] = (buckets[ch] or []).push(str)
    end
  end

  unless buckets.empty? then
    ptrns = buckets.collect do |key, value|
      [key].pack('C') + process_list(value.map{|item| item.pack('C*') }).to_s
    end

    if optional == true then
      "(" + ptrns.join("|") + ")?"
    elsif ptrns.length > 1 then
      "(" + ptrns.join("|") + ")"
    else
      ptrns
    end
  end
end

def print_pattern(name, list)
  return unless list = process_list(list)
  puts <<-END
{	name = '#{ name }';
match = '(?i)\\b#{ list }\\b';
},
  END
end

def print_completion_data(name, prototype, description)
  @completion_data.puts [name, prototype, description].map{|s| s.to_s.strip }.join('%')
end

data = File.read(functions_file).strip
@completion_data = File.open('../lib/functions.txt', 'w')

sections = data.split(/^#.+\/(?:zend_)?(.+)\..+$/)[1..-1]

classes     = [] # Stored class names, for a pattern at the end
completions = [] # List of all function names for completion

ConstructFunctions.each do |(function, info)|
  print_completion_data(function, info[0], info[1])
end

sections.each_slice(2) do |(section, functions)|
  functions = functions.strip.split(/$/)
  function_names = []
  functions.each_slice(2) do |(prototype, description)|
    if prototype =~ /(\w+)::/
      # Class method
      # Ignore the method but add class name to a list
      classes << $1
    else
      if prototype.strip.match(/(\w+)\s*\(/)
        function_names << $1 
        print_completion_data($1, prototype, description)
      end
    end
  end
  completions += function_names
  print_pattern("support.function.#{section}.php", function_names)
end

print_pattern('support.function.construct', ConstructFunctions.keys)
print_pattern('support.class.builtin', classes)

xml = Builder::XmlMarkup.new(:indent => 2, :target => File.open('../../Preferences/Completions.tmPreferences', 'w'))
xml.instruct!
xml.declare! :DOCTYPE, :plist, :public, "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"
xml.plist :version => '1.0' do
  xml.dict do
    xml.key 'name'
    xml.string 'Completions'
    xml.key 'scope'
    xml.string 'source.php'
    xml.key 'settings'
    xml.dict do
      xml.key 'completions'
      xml.array do
        completions.each do |function_name|
          xml.string function_name
        end
      end
    end
    xml.key 'uuid'
    xml.string '2543E52B-D5CF-4BBE-B792-51F1574EA05F'
  end
end
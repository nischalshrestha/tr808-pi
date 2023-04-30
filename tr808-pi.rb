# global map for sample to:
# - path (location of sample dir)
# - version (which file to pick for sample when there are multiple)
# - hits (Hash<String, List> where keys represent names of patterns, and List is hits)
# then some custom params for sample arguments like BD_amp for amp
# which will initially set by `setup_samples()`
$samples_map = {}

$tr808_abbrevs = [
  "BD", # has multiple versions
  "SD", # has multiple versions
  "LT", # has multiple versions
  "MT", # has multiple versions
  "HT", # has multiple versions
  "LC", # has multiple versions
  "MC", # has multiple versions
  "HC", # has multiple versions
  "RS",
  "CL",
  "CP",
  "MA",
  "CB",
  "CY", # has multiple versions
  "OH", # has multiple versions
  "CH"
]

def setup_samples()
  """
  Initializes the $samples_map hash to map instrument -> params.

  Returns:
      nil
  """
  sample_location = File.dirname(__FILE__) + '/TR808_Samples'
  $tr808_abbrevs.each do |s|
    amp_param = "#{s}_amp".to_sym
    path = "#{sample_location}/#{s}"
    sym_key = s.to_sym
    $samples_map[sym_key] = {
      :path => path,
      :version => 1, # which file to pick for samples
      # hits is a Hash that looks like this:
      # {"A": [0..n], "B": [0..n], ... }
      :hits => {}
    }
    set amp_param, 1.5
  end
end

def inst_to_binary(splitlines, pattern_name=0)
  # first, we map each instrument to its hit pattern
  inst_to_hits = splitlines.map{
    |line|
    line.split(" ")
  }

  # helper function to split notes of an instrument Integero an array of 1s and 0s
  def make_hits(hit_strs)
    splits = hit_strs.tr('x-', '10').split('')
    splits = splits.reject { |item| item == "|" }
    return splits.map(&:to_i)
  end

  # make a Hash out of the list pair ["inst", [0..n]]
  # such that values represent named pattern
  return inst_to_hits.map{
    |k, v| [k.to_sym, {pattern_name => make_hits(v)}]
  }.to_h
end

def parse_beat(src)
  """
  Return a dictionary representing a beat pattern for the TR-808.

  Args:
      src (String, Array<String>, Hash<String, String>): 
      The string(s) representing the beat pattern.

  Returns:
      The dictionary.
  """
  setup_samples()

  # helper function to update the $samples_map
  def set_hits(hits)
    hits.each do |inst, hits_dict|
      $samples_map[inst][:hits] = hits_dict
    end
  end

  if src.class == String
    # remove indents, leading/trailing newlines, and split on newlines
    splitlines = src.gsub(/^\s+/, '').strip.split("\n")
    hits = inst_to_binary(splitlines)
    set_hits(hits)
  elsif src.class == Array
    # for multiple patterns, create hits for each pattern
    final_hits = {}
    src.each_with_index do |pattern, index|
      pattern = pattern.gsub(/^\s+/, '').strip
      # by default, pattern for each pattern is the index
      hits = inst_to_binary(pattern.split("\n"), pattern_name = index)

      # initialize the final hits hash if it's the first entry
      if final_hits.length == 0
        final_hits = hits
      else
        # otherwise, update the hits hash of each instrument
        # in final_hits so we add more patterns
        hits.each do |name, pattern|
          # pp final_hits[name]
          final_hits[name] = final_hits[name].merge(pattern)
        end
      end
    end
    
    set_hits(final_hits)
  elsif src.class == Hash
    # for multiple named patterns, create hits for each pattern with 
    # name specified by user
    final_hits = {}
    src.each do |name, pattern|
      pattern = pattern.gsub(/^\s+/, '').strip
      hits = inst_to_binary(pattern.split("\n"), pattern_name = name)

      # initialize the final hits hash if it's the first entry
      if final_hits.length == 0
        final_hits = hits
      else
        # otherwise, update the hits hash of each instrument
        # in final_hits so we add more patterns
        hits.each do |name, pattern|
          final_hits[name] = final_hits[name].merge(pattern)
        end
      end
    end
    set_hits(final_hits)
  end
end

# we can use a function that takes a mapping of instrument to filepath
# to sample the instrument with some special logic to choose a particular
# version for ones with multiple versions
def sample_tr808(inst)
  """
  Return a dictionary representing a beat pattern for the TR-808.

  Note: some instruments like bass drum or 'BD' have multiple versions.
  For now, we have hand-picked one version to pick but in the future we
  could leave that up to the user to pick. 

  Args:
      inst (String): The string representing the abbreviated TR-808 instrument.
      For example, 'BD' for bass drum

  Returns:
      nil
  """
  sound = $samples_map[inst]
  sym_key = "#{inst}_amp".to_sym
  sample sound[:path], sound[:version], amp: get[sym_key]
end

def tr808(src, bpm: 90, pattern: [0])
  """
  Play a live loop of the TR-808 given a beat pattern(s) and bpm.

  Args:
      src (String, Array<String>, Hash<String, String>): 
        The string(s) representing the TR-808 beat pattern(s).
        
        For 1 pattern, provide a String for the pattern. For multiple
        patterns that are not named, provide an Array of Strings.
        
        If you want to name each pattern, provide a Hash with the key
        representing the name of pattern and the value as the String pattern.
      bpm (Integer): The bpm, 90 by default.
      pattern (Array<Integer>, Array<String>): 
        An array of which pattern to play if there are 
        multiple patterns, [0] by default for one single pattern. 
        
        For specifying names of the pattern provide an Array of String(s).
  Returns:
      nil
  """
  parse_beat(src)
  note_value = 0.5 # eighth note

  live_loop :tr808 do
    use_bpm bpm
    # tick through the pattern array to switch between different patterns
    cur_pattern = pattern.tick
    # tr808 is 16 notes per measure
    16.times do |i|
      # for each instrument, play the sample if it's a hit
      $samples_map.each do |inst, values|
        hits = values[:hits]
        if hits.length && hits.has_key?(cur_pattern) && hits[cur_pattern][i] == 1
          sample_tr808(inst)
        end
      end
      # 16th notes
      sleep note_value / 2
    end
  end
end

def tweak(inst, **params)
  """
  Tweak a particular instrument's parameter.

  Currently only allows changing `amp`

  Args:
      inst (String): The string representing the instrument (e.g. 'bd' or 'BD')
      params (Hash): Any number of keyword args representing {param: value}

  """
  inst_sym = inst.upcase.to_sym

  if $samples_map.has_key?(inst_sym)
    params.each do |arg, value|
      arg_sym_key = "#{inst_sym.to_s}_#{arg}".to_sym
      set arg_sym_key, value
    end
  end
end


# global map for sample to:
# - path (location of sample dir)
# - version (which file to pick for sample when there are multiple)
# - hits (whether to play the instrument or not)
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
      :hits => []
    }
    set amp_param, 1.5
  end
end

def parse_beat(src)
  """
  Return a dictionary representing a beat grid for the TR-808.

  Args:
      src (int): The string representing the beat grid.

  Returns:
      The dictionary.
  """
  setup_samples()

  splitlines = src.strip.split("\n")
  
  # first, we map each instrument to its hit pattern
  inst_to_hits = splitlines.map{
    |line|
    line.split(" ")
  }
  
  # then, create a dictionary of inst => [0s, 1s]
  inst_to_binary = inst_to_hits.map{
    |k, v| [k.to_sym, v.tr('x-', '10').split('').map(&:to_i)]
  }.to_h

  # update global $samples_mapping
  inst_to_binary.each do |k, v|
    $samples_map[k][:hits] = v
  end

end

# we can use a function that takes a mapping of instrument to filepath
# to sample the instrument with some special logic to choose a particular
# version for ones with multiple versions
def sample_tr808(inst)
  """
  Return a dictionary representing a beat grid for the TR-808.

  Note: some instruments like bass drum or 'BD' have multiple versions.
  For now, we have hand-picked one version to pick but in the future we
  could leave that up to the user to pick. 

  Args:
      inst (str): The string representing the abbreviated TR-808 instrument.
      For example, 'BD' for bass drum

  Returns:
      nil
  """
  sound = $samples_map[inst]
  sym_key = "#{inst}_amp".to_sym
  sample sound[:path], sound[:version], amp: get[sym_key]
end

def tr808(src, bpm: 90)
  """
  Play a live loop of the TR-808 given a beat grid and bpm.

  Args:
      src (str): The string representing the TR-808 beat grid.
      bpm (int): The bpm, 90 by default.

  Returns:
      nil
  """
  parse_beat(src)
  note_value = 0.5 # eighth note

  live_loop :tr808 do
    use_bpm bpm
    # tr808 is 16 notes per measure
    16.times do |i|
      # for each instrument, play the sample if it's a hit
      $samples_map.each do |inst, values|
        if values[:hits][i] == 1
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
      inst (str): The string representing the instrument (e.g. 'bd' or 'BD')
      params (hash): Any number of keyword args representing {param: value}

  """
  inst_sym = inst.upcase.to_sym

  if $samples_map.has_key?(inst_sym)
    params.each do |arg, value|
      arg_sym_key = "#{inst_sym.to_s}_#{arg}".to_sym
      set arg_sym_key, value
    end
  end
end

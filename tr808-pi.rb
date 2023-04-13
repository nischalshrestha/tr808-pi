
sample_tr808_grid = \
"
BD x-----xx--x----x
SD ----x-------x---
LT ----------------
MT ----------------
HT ------xx--x--x--
LC ----------------
MC ----------------
HC ----------------
RS ---x--xxx-------
CL ----------------
CP x--------------x
MA ----------------
CB ----------------
CY ----------------
OH ----------------
CH x-xxx-xxx-xxx-xx
"

def parse_beat(src)
  """
  Return a dictionary representing a beat grid for the TR-808.

  Args:
      src (int): The string representing the beat grid.

  Returns:
      The dictionary.
  """
  splitlines = src.strip.split("\n")
  
  # first, we map each instrument to its hit pattern
  inst_to_hits = splitlines.map{
    |line|
    line.split(" ")
  }
  
  inst_to_binary = inst_to_hits.map{
    |k, v| [k, v.tr('x-', '10').split('').map(&:to_i)]
  }.to_h
  
  return inst_to_binary
end

def get_inst_to_sample
  """
  Return a dictionary that maps instrument to sample path for the TR-808.

  Returns:
      The dictionary.
  """
  sample_location = File.dirname(__FILE__) + '/TR808_Samples'
  puts sample_location
  tr808_abbrevs = [
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
  return tr808_abbrevs.map{|inst| [inst, "#{sample_location}/#{inst}"]}.to_h
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
  mapping = get_inst_to_sample
  case inst
  when "CY"
    sample mapping[inst], "0000", amp: 1
  when "BD"
    sample mapping[inst], "1000", amp: 3
  else
    sample mapping[inst], 1, amp: 1
  end
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
  samples_map = parse_beat(src)
  note_value = 0.5 # eighth note

  live_loop :tr808 do
    use_bpm bpm
    # tr808 is 16 notes per measure
    16.times do |i|
      # for each instrument, play the sample if it's a hit
      samples_map.each do |inst, hit|
        if hit[i] == 1
          sample_tr808(inst)
        end
      end

      # 16th notes
      sleep note_value / 2
    end
  end
end

def sequencer(src, bpm: 90)
  """
  Play a live loop of a note sequencer given a note grid and bpm.

  Args:
      src (str): The string representing the sequencer grid.
      bpm (int): The bpm, 90 by default.

  Returns:
      nil
  """
  samples_map = parse_beat(src)
  note_value = 0.5 # eighth note

  with_synth :saw do
    live_loop :sequencer do
      use_bpm bpm
      # note sequencer is also 16 notes per measure
      16.times do |i|
        # for each note, play it if it's a hit
        samples_map.each do |note, hit|
          if hit[i] == 1
            play note: note, attack: 0
          end
        end
        # 16th notes
        sleep note_value / 2
      end
    end
  end
end

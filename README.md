# tr808-pi

<img alt="A DALL-E picture from a prompt: A drum machine next to a piece of pie" src="./images/A_drum_machine_next_to_a_piece_of_pie.png" width="400" height="400">

*Art made by [Craiyon, formerly DALL·E mini](https://www.craiyon.com). The prompt: A drum machine next to a piece of pie.*

This project is a demonstration of emulating the Roland TR-808 drum machine in Sonic Pi. I was  inspired by GUI-based versions such as [tr808r](https://coolbutuseless.github.io/package/tr808r/) and [Roland's online version of TR-808](https://roland50.studio) and decided to make a lightweight text-based version. The samples were taken from [this free resource by Michael Fischer](http://machines.hyperreal.org/manufacturers/Roland/TR-808/).

## How do I get it?

All you need to do is download this git repo as a zip, unarchive it somewhere on your computer.

In Sonic Pi, you then `require` the filepath for the main file `tr808-pi.rb` at the top of your file:

```rb
require "~/Documents/projects/tr808-pi/tr808-pi.rb"
```

## How do I use it?

To play the TR-808, you pass a string format to `tr808()` that represents the beat pattern, where:

- the left-hand side is the specific instrument (e.g. `BD` for bass drum)
- followed by a space
- and 16 `x` (play the note) or `-` (do not play the note) with `|` for visual separation of notes

Here's an example of the beat for "1000 Knives" by Yellow Magic Orchestra:

```
BD xx--|----|xx--|----
SD ----|----|----|----
LT ----|----|----|----
MT ----|----|----|----
HT ----|----|----|----
LC ----|----|----|----
MC ----|----|----|----
HC ----|----|----|----
RS ----|x---|----|x---
CL ----|----|----|----
CP ----|----|----|--x-
MA ----|----|----|----
CB ----|----|----|----
CY ----|----|----|----
OH ----|x---|----|x---
CH --xx|---x|--xx|---x
```

Note: refer to the [TR808.TXT file of the sample pack](./TR808_Samples/TR808.txt) on what sounds the abbreviations map to.

You do not have to worry about new lines before or after the `"`. There is no error handling but since this is going to be played in a live loop context it won't matter if you mess up the number of notes or `|`: it will just affect when the notes are played.

Here's an example of playing the beat above by passing it to `tr808()` with some of the instruments removed since they're not used.

```rb
tr808("
BD xx--|----|xx--|----
RS ----|x---|----|x---
CP ----|----|----|--x-
OH ----|x---|----|x---
CH --xx|---x|--xx|---x
", bpm: 104)
```

In the above example, we have a live beat pattern with various instruments playing in a measure which is 16 notes in total. This will keep playing indefinitely because it is a `live_loop` under the hood. Tweak the `x`'s and `-`'s to explore all the fun possibilities!

## Multiple patterns

It wouldn't be fun if you could only create one set of beat patterns, so you can also specify multiple patterns.

To add another pattern you simply need to pass in a list of strings and optionally specify the order to play each pattern with a `pattern:` parameter that accepts an array of integers corresponding to an item.

Let's modify the above example to add a different pattern:

```rb
tr808([
"
BD xx--|----|xx--|----
RS ----|x---|----|x---
CP ----|----|----|--x-
OH ----|x---|----|x---
CH --xx|---x|--xx|---x
",
"
BD xx--|----|xx--|---x
RS ---x|----|---x|----
CP ----|---x|----|-x-x
OH ----|x---|----|x---
CH --xx|----|--xx|----
"
], 
bpm: 104)
```

Without the `pattern:` argument being set, the `tr808()` will only play the first pattern. So, let's say we want to play each pattern in succession:

```rb
tr808([
"
BD xx--|----|xx--|----
RS ----|x---|----|x---
CP ----|----|----|--x-
OH ----|x---|----|x---
CH --xx|---x|--xx|---x
",
"
BD xx--|----|xx--|---x
RS ---x|----|---x|----
CP ----|---x|----|-x-x
OH ----|x---|----|x---
CH --xx|----|--xx|----
"
], 
bpm: 104, pattern: [0, 1])
```

By specifying `pattern: [0, 1]`, this plays the first pattern for the first measure, then the second and then cycle back to the first. You can still keep modifying the beat in either pattern and Sonic Pi will pick up the change in the next 16 notes!

## Share your beats!

This string is also copy-paste-able text so that you can easily share it with others! The character length is a bit too long for tweets if you choose to use all the instruments. However, you can choose to use only a subset of the instruments, and can remove some. For example, transforming the long example above fits in a tweet:

```
BD xx--|----|xx--|----
RS ----|x---|----|x---
CP ----|----|----|--x-
OH ----|x---|----|x---
CH --xx|---x|--xx|---x
```

If it's too long, you can [create a gist](https://gist.github.com) and share the link.

Happy beat making y'all!

You can refer to some popular TR-808 beats [here](http://808.pixll.de/index.php).

> **NOTE:** there is no error handling at all so the string format is strict for now. If time permits, I will add enhancements to protect the user, and allow further tweaks to the way the notes are played.

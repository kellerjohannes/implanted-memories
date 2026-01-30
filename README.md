# Implementation of 'implanted memories' by Polina Korobkova

In 2019, [Polina Korobkova](https://polinakorobkova.com/) composed her
work _implanted memories_ for the performance series
[_Illuminationen_](https://www.garedunord.ch/en/calendar/2480/illuminationen-nr-5-automat-und-organismus-michael-kleine-johannes-keller)
at Gare du Nord Basel. She provided a sketch of a graphical score,
which was the starting point for Johannes Keller's implementation. The
final piece is exclusively notated in computer code. Johannes decided
to use the [Extempore](https://extemporelang.github.io/) language,
since it's aimed at live coding.

The code is used to remotely play the
[Arciorgano](https://www.projektstudio31.com/instruments), a
reconstruction of a microtonal organ of the 16th century. The code
also controls the switches for the electric organ blower and for a
light bulb. Additionally the playback of a video is also triggered
(either through a [Max](https://cycling74.com/) patch or a
[PureData](https://puredata.info/) patch).

This code was used to perform this piece on the 5th of December 2019
at Gare du Nord Basel, and on the 11th of December 2021 at Kunstraum
Walcheturm in Zürich.

To run the code for a revival, use implanted-memories-clean.xtm, after
loading arciorgano-comm.xtm and implanted-memories-midi.xtm.

To troubleshoot the remote player module, please refer to the
[Arciorgano Player
patch](https://github.com/kellerjohannes/arciorgano-player).


In January 2026, Lin Korobkova reworked the entire piece for a performance on the 6th of February 2026 at the ECLAT festival in Stuttgart. This required an entirely new implementation. Since Lin notated the entire piece in staff notation, it seemed pointless to create program code to generate the musical events. Instead, the score was manually converted to MIDI, using Reaper. In an early stage of this process, Johannes Keller attempted to compute certain effects with a tool written in Common Lisp, mainly glissandi and dynamics. Since the score is very much deteministic and the effects needed to be finetunged manually anyways, this approach was to cumbersome. Therefore the Stuttgart manifestation of this piece is performed entirely from Reaper sending MIDI to the old PureData patch that converts the MIDI events into serial data sent to the player module of the Arciorgano.



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

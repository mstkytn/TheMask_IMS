TheMaskProject2 (py- osc, openCV)
// 2 den sonra, b buffer ını record et, sonra 3 ü çalıştır, ~play çal, ~play free bırak
//loop : record + play + free
// Setup
// 1 sETTING uP tHE iNITIALS +
(
s.boot;
(
s.options.inDevice = "Built-in Microph";
s.options.numInputBusChannels = 4;
s.options.outDevice = "Built-in Output";
s.options.numOutputBusChannels = 4;
);
(
s.makeGui(f);
s.meter;
s.scope;
s.freqscope;
s.plotTree;
);
)

// 2 rECORD bUFFER +
(
~t = 4;
b = Buffer.alloc(s, 44100 * ~t, 1);
(~rec = SynthDef(\rec, {|out = 0, bufnum = 0|
	var record;
	record = SoundIn.ar(0);
	RecordBuf.ar(record, bufnum,trigger: 1, doneAction: Done.freeSelf, loop: 0);
}))
)

//* sTARTER rECORD
~rec.play(s,[\out, 0, \bufnum, b]);

// 3 sONIC mATERIAL
(x = (SynthDef(\TheSound, {
		|room =10, revt = 1, amp = 0.01,dcy = 1,
		phs = 1, rate = 0.5, spr = 20, pR = 1, pan = 0.1,
		dly = 0.2|
	var freq = Pitch.kr(SoundIn.ar(0));
	var buf = PlayBuf.ar(1, b, rate,SinOsc.kr((rate)/(~t )));
	var rev = GVerb.ar(buf, room, revt,spread: spr);
	var ps = PitchShift.ar(buf,pitchRatio: pR);
	var fs = FreqShift.ar(ps,freq,phs);
	var pnd = Pan2.ar(fs,pan);
	var prev = FreeVerb2.ar(pnd,pnd);
	var pdel = 	CombC.ar(prev,0.3, dly,dcy);
		Out.ar(0,pdel) * amp})))

// 4 oSC fUNDAMENTAL TDEFs +
(Tdef(\PLAY,
		     {"Manipulate It!".postln;
			  ~play = x.play;
		      52.wait;
			  "The End, Thanks for the performance!".postln;
			  ~play.free;}))

// 5 oSC aDDRESS
(thisProcess.openUDPPort(57121);
thisProcess.openPorts)

// 6 mAPPING
(Spec.add(\freq, [-600, 1200, \lin]);
\freq.asSpec;
Spec.add(\room, [0, 100, \lin]);
\room.asSpec;
Spec.add(\revt, [0, 100, \lin]);
\revt.asSpec;
Spec.add(\amp, [0.01, 0.2, \lin]);
\amp.asSpec;
Spec.add(\rate, [1, 10]);
\rate.asSpec;
Spec.add(\pR, [0.0001, 4, \lin]);
\pR.asSpec;
Spec.add(\pan, [-1, 1, \lin]);
\pan.asSpec;
Spec.add(\dly, [0.001, 1, \lin]);
\dly.asSpec;
Spec.add(\dcy, [0.001, 1, \lin]);
\dcy.asSpec;
/* henüz net değil
Spec.add(\spr, [0.001, 1, \lin]);
\spr.asSpec;
Spec.add(\phs, [0.001, 1, \lin]);
\phs.asSpec;
*/)

// 7 oSC dEFS + Alternative Mapped
(
OSCdef.new(\OSC1, {
	arg msg, time, address, port, rp;
	msg.postln;
	rp = msg[1];
	if (rp == 'R')
		{~rec.play(s,[\out, 0, \bufnum, b]);"RECORDING".postln}
		{ if (rp == 'P')
			{Tdef(\PLAY).play;"PLAYING".postln}
			{if (rp == 'M')
				{
//					~play.set(\freq, \freq.asSpec.map(msg[2]*3 - 600).postln); // FREQ
					~play.set(\room, \room.asSpec.map(msg[3] / 12 ).postln); // ROOM
					~play.set(\revt, \revt.asSpec.map(msg[4] / 12).postln); // REVT
//					~play.set(\amp, \amp.asSpec.map(msg[5] / 100).postln); // AMP
					~play.set(\rate, \rate.asSpec.map(msg[8] / 30).postln); // RATE
//					~play.set(\pR, \pR.asSpec.map(msg[10] / 250).postln); // PITCH RATIO
//					~play.set(\pan, \pan.asSpec.map(msg[11]/ 1200 - 1).postln); // PAN
//					~play.set(\dly, \dly.asSpec.map(msg[12] / 1200).postln); // DELAY
//					~play.set(\dcy, \dcy.asSpec.map(msg[6] / 1200).postln); // DECAY
//--				~play.set(\spr, \spr.asSpec.map(msg[9] / 600).postln); // SPREAD
//--				~play.set(\phs, \phs.asSpec.map(msg[7] / 600).postln); // PHASE
/*					~play.set(\xxx, \xxx.asSpec.map(msg[2] / 600).postln); // EYE AXIS
					~play.set(\xxx, \xxx.asSpec.map(msg[2] / 600).postln); // MOUTH AXIS
*/
				}
				{if (rp == 'S')
					{~play.free;"STOPPED".postln}
					{}
				}
			}
		}
},'/pyOsc')
);

						   #THE END OF THE PROJECT#
>>>>>>>>>>>>>>>>>>>>>>>>>                           <<<<<<<<<<<<<<<<<<<<<<<<<<<<

// TESTS   ---------------------------------------------START
// OSCTEST
OSCFunc.trace(false)
OSCFunc.trace(true)

~rec.play(s,[\out, 0, \bufnum, b]) // RECORDERTEST
b.play // PLAYERTEST
b.free
// TESTS   ---------------------------------------------END

// MANIPULATION TESTS  ---------------------------------------------START

(
(x = (SynthDef(\TheSound, {
		|freq = 440, room =10, revt = 1, amp = 1,dcy = 1,
		phs = 10, rate = 0.5, spr = 20, pR = 1, pan = 0.1,
		dly = 0.2|
	var buf = PlayBuf.ar(1, b, rate,SinOsc.kr((rate)/(~t )));
	var rev = GVerb.ar(buf, room, revt,spread: spr);
	var ps = PitchShift.ar(buf,pitchRatio: pR);
	var fs = FreqShift.ar(ps,freq,phs);
	var pnd = Pan2.ar(fs,pan);
	var prev = FreeVerb2.ar(pnd,pnd);
	var pdel = 	CombC.ar(prev,0.3, dly,dcy);
		Out.ar(0,pdel) * amp}
)));

~play = x.play //found
)

~play.free


------ MANIPULATION

~play.set(\freq, 240) // mouth width
~play.set(\room, 1) //mouth height
~play.set(\revt, 1) // orientation
~play.set(\amp, 1) //*****
~play.set(\rate, 2.1) //  center pose
~play.set(\spr, 100) // nosetril
~play.set(\pR,1) // scale
~play.set(\pan, 0) // left eye + right eye
~play.set(\dly, 80) // left eye~playrow
~play.set(\dcy, 1) // right eye~playrow
~play.set(\phs, 0.6) // jaw openness

------ END

// MANIPULATION TESTS  ---------------------------------------------END


~play = x.play //found
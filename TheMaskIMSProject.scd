TheMaskProject (py- osc, openCV)
// Setup
// 1 sETTING uP tHE iNITIALS +
(
s.boot;
(
s.options.inDevice = "Built-in Microph";
s.options.numInputBusChannels = 2;
s.options.outDevice = "Built-in Output";
s.options.numOutputBusChannels = 2;
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
		phs = 1, rate = 0.5, spr = 20, pR = 1, pan = 1,
		dly = 0.2|
	var freq = Pitch.kr(SoundIn.ar(0));
	var buf = PlayBuf.ar(1, b, rate,SinOsc.kr((rate)/(~t )));
	var rev = GVerb.ar(buf*0.4, room, revt,spread: spr);
	var ps = PitchShift.ar(buf,pitchRatio: pR);
	var fs = FreqShift.ar(ps,freq-400,phs);
	var pnd = Pan2.ar(fs,ps);
	var prev = FreeVerb2.ar(pnd,rev);
	var pdel = CombC.ar(prev,0.3, dly,dcy);
	var norm = Normalizer.ar(pdel,0.1,0.2);
	var end = Limiter.ar(norm,amp,0.2);
		Out.ar(pan,end)})))

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
(
Spec.add(\pan, [0, 1, \lin]);
\pan.asSpec;
Spec.add(\dly, [0.2, 0.5, \lin]);
\dly.asSpec;
Spec.add(\rate, [-4, 4], \lin);
\rate.asSpec;
Spec.add(\pR, [0.001,20, \lin]);
\pR.asSpec;
Spec.add(\amp, [0.01, 0.06, \exp]);
\amp.asSpec;
Spec.add(\dcy, [-0.2, 0.4, \lin]);
\dcy.asSpec;
Spec.add(\phs, [0.1, 10, \lin]);
\phs.asSpec;
Spec.add(\spr, [-100, 100, \lin]);
\spr.asSpec;
Spec.add(\room, [0, 1, \lin]);
\room.asSpec;
Spec.add(\revt, [0, 0.15, \lin]);
\revt.asSpec;
Spec.add(\freq, [-600, 1200, \lin]);
\freq.asSpec;
)

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
				~play.set(\pan, \pan.asSpec.map((msg[2]/640)).postln); // PAN
				~play.set(\dly, \dly.asSpec.map(msg[3]/120).postln); // DELAY
				~play.set(\rate, \rate.asSpec.map((msg[4]-40)/460).postln); // RATE
				~play.set(\pR, \pR.asSpec.map(msg[5] / 250).postln); // PITCH RATIO
				~play.set(\amp, \amp.asSpec.map(msg[6] / 100).postln); // AMP
				~play.set(\dcy, \dcy.asSpec.map(msg[7] / 200).postln); // DECAY
				~play.set(\phs, \phs.asSpec.map(msg[8] / 440).postln); // PHASE
				~play.set(\spr, \spr.asSpec.map((msg[9] + 50) / 100).postln); // SPREAD
				~play.set(\room, \room.asSpec.map(msg[10]/10).postln); // ROOM
				~play.set(\revt, \revt.asSpec.map(msg[11] / 1100).postln); // REVT
				}
				{if (rp == 'S')
					{~play.free;"STOPPED".postln}
					{}
				}
			}
		}
},'/pyOsc')
)

--
s.record()
--
s.stopRecording()

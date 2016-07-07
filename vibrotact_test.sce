###################################################################################################################################
# Test script for the fMRI compatible piezoelectric vibratory stimulation system	build by Mag Design & Engineering					 #
# Tests all stimulators individually with all available frequencies										 											 #
#																																 											 #
# Script written by Jasper Wijnen																			 													 #
# Requested by Yael Salzer																																			 #
# TOP, University of Amsterdam, February 2016																												 #
# Using NBS Presentation 18.2																																		 #
###################################################################################################################################


default_font = "calibri";
default_font_size = 26;

begin;


text{caption="stimulator test";}test1_txt;
text{caption="testing";}test2_txt;


picture{
	text test1_txt;x=0;y=300;
	text test2_txt;x=0;y=0;
}test_pic;


begin_pcl;

output_port outport = output_port_manager.get_port(1);		#LPT data I/O register, switches individual stims on/off
array <int> portcodes [8] = {1,2,4,8,16,32,64,128};

dio_device freq_ctrl = new dio_device(memory_dio_device,890,4); #LPT control I/O register, controls vibratory frequency
#value 890 is dec conversion from hexadecimal adress 0378, this is the I/O range for LPT port on adress D050 + 2 
#if LPT adress is different for your PC you should change this value

array <int> freqcodes [16]; freqcodes.fill(1,0,0,1);
array <int> freqs [16];freqs.fill(1,0,30,30);

loop int f=1; until f>16 begin
	freq_ctrl.write(1,freqcodes[f]);
	
	loop int x=1 until x>portcodes.count() begin
		
		test2_txt.set_caption("testing stim: " + string(x) + "\nport code: " + string(portcodes[x]) + "\n f value: " + string(freqcodes[f]) + "\nsupposed frequency: " + string(freqs[f]),true);
		test_pic.present();
		outport.send_code(portcodes[x],150);
		wait_interval(200);
		
		x=x+1;
	end;
	
	f=f+1;
end;



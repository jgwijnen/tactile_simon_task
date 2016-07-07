###########################################################################################################################################################
# fMRI compatible somatosensory moving-dot-paradigm using the piezoelectric vibratory stimulation system	build by Mag Design & Engineering					 #
#																																 											 								 #
# Script written by Jasper Wijnen																			 													 								 #
# Requested by Yael Salzer																																			 								 #
# TOP, University of Amsterdam, February 2016																												 								 #
# Using NBS Presentation 18.2																																		 								 #
###########################################################################################################################################################

active_buttons = 3;		#up, down, esc
default_font = "calibri";
default_font_size = 26;

begin;

TEMPLATE "tactile_movdot.tem";

begin_pcl;

string move = "movefreq";

output_port outport = output_port_manager.get_port(1);		#LPT data I/O register, switches individual stims on/off
array <int> portcodes [8] = {1,2,4,8,16,32,64,128};


dio_device freq_ctrl = new dio_device(memory_dio_device,53330,4); #LPT control I/O register, controls vibratory frequency
#value 53330 is dec conversion from hexadecimal adress D052, this is the higher I/O range for LPT port on adress D050 + 2 
#if LPT adress is different for your PC you should change this value

array <int> freqcodes [16]; freqcodes.fill(1,0,0,1); 
#array <int> freqs [16];freqs.fill(1,0,30,30);


include "soma_movdot_subs.pcl";


array<int> trial_type[5][5];
array<int> trial_type_freqs[5][10];

array<int> trial_type_template[4][10];

trial_type_template[1] = {4,5,6,5,4,4,4,5,6,6};
trial_type_template[2] = {4,3,2,3,4,4,4,3,2,2};
trial_type_template[3] = {4,5,6,5,4,4,4,3,2,2};
trial_type_template[4] = {4,3,2,3,4,4,4,5,6,6};

array<int> singlestim_template[14]; singlestim_template.fill(1,0,4,0);

int nr_of_trials = 60;

array<int> trial_con[nr_of_trials];

trial_con.assign(advarrayfill(nr_of_trials,1,4));
trial_con.shuffle();


trial_type_freqs[1].fill(1,0,210,0);

array<int> trial_freq_template[4][14];

trial_freq_template[1] = {240,210,180,210,240, 240,210,180,150, 120,90,60,30,30};
trial_freq_template[2] = {240,270,300,270,240, 240,270,300,330, 360,390,420,450,480};
trial_freq_template[3] = {240,210,180,210,240, 240,270,300,330, 360,390,420,450,480};
trial_freq_template[4] = {240,270,300,270,240, 240,210,180,150, 120,90,60,30,30};


array<string> trialcon_cg [4] = {"congruent","congruent","incongruent","incongruent"};
array<string> trialcon_mapping [4] = {"down", "up", "up", "down"};

/*
trial_type[2] = {4,3,3,3,1};
trial_type[3] = {4,5,3,7,2};
trial_type[4] = {4,4,4,4,4};
trial_type[5] = {4,3,2,1,1};
*/

#starttrial(trial_type_freqs[1],trial_type[1],200,100,true);


include "tactile_movdot_shared.pcl";

/*
output_file out = new output_file();
out.open(logfile.subject() + "_tactmovdot.txt");
out.print("trialnr\tfreqs\tstims\tdur\tdelay\tresp\tRTn");

choice_pic.add_part(UD_text,0,0);

loop int z=1 until z>nr_of_trials begin

	array<int>current_sequence [0];
	current_sequence.assign(trial_freq_template[trial_con[z]]);	
	current_sequence.assign(add_noise(current_sequence,true));
	
	LR_pic.present();
	
	int starttime = clock.time();	
	int resp1 = response_manager.total_response_count(1);
	int resp2 = response_manager.total_response_count(2);
	int resp3 = response_manager.total_response_count(3);
	int decision=0;int RT=0;
	
	######################################################################
	starttrial(current_sequence,singlestim_template,200,100,true);
	######################################################################
	
	out.print(z);out.print("\t");
	
	loop until decision !=0 begin
		if resp1 < response_manager.total_response_count(1) then
			RT = response_manager.last_response_data().time() - starttime;
			decision=1;		
		elseif resp2 < response_manager.total_response_count(2) then
			RT = response_manager.last_response_data().time() - starttime;
			decision=2;
		elseif resp3 < response_manager.total_response_count(3) then
			exit();
		end;
	end;
	
	FB_txt.set_caption("decision: " +string(decision) + "\nRT: " + string(RT), true);
	FB_pic.present();
	wait_interval(500);
	
	empty_pic.present();

	z=z+1;
end;


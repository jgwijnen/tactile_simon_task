##############################################################################################################################################################
# Tactile simontask used in combination with the fMRI compatible piezoelectric vibratory stimulation system	build by Mag Design & Engineering					 #
# 																																 											 									 #
# Script written by Jasper Wijnen																			 													 									 #
# Requested by Yael Salzer																																			 			 						 #
# TOP, University of Amsterdam, March 2016																													 			 						 #
# Using NBS Presentation 18.2																																		 			 						 #
##############################################################################################################################################################

default_font = "calibri";
default_font_size = 22;
default_text_color = 0,0,0;
default_background_color = 255,255,255;

response_matching = simple_matching;

active_buttons =4;		#left, right space

scenario_type = fMRI;
pulses_per_scan = 1;
pulse_code = 255;

begin;

text{caption="<b>+</b>";font_size=40;formatted_text=true;}fixblack_txt;
text{caption="<b>+</b>";font_size=40;formatted_text=true;font_color=255,0,0;}fixred_txt;

text{caption=" ";font_size=40;formatted_text=true;}debug1_txt;
text{caption=" ";font_size=40;formatted_text=true;}debug2_txt;
text{caption=" ";font_size=40;formatted_text=true;}debug3_txt;

picture{text fixblack_txt;x=0;y=0;}default;
picture{
	text fixblack_txt;x=0;y=0;
	/*text debug1_txt;x=-400;y=-400;
	text debug2_txt;x=-400;y=-450;
	text debug3_txt;x=-400;y=-500;*/
}fixblack_pic;
picture{
	text fixred_txt;x=0;y=0;
	/*text debug1_txt;x=-400;y=-400;
	text debug2_txt;x=-400;y=-450;
	text debug3_txt;x=-400;y=-500;*/
}fixred_pic;
picture{}stim_pic;

trial{
	
	stimulus_event{
		picture fixblack_pic;
		code = "blackfix1";
	}blackfix_event;
	stimulus_event{		
		picture fixred_pic;
		deltat=296;
		code = "redfix";
	}redfix_event;
	stimulus_event{		
		picture stim_pic;
		deltat=296;							#onset of current event
		response_active=true;		
		code = "Visstim";	
		duration = 446;					#duration visual stim
	}main_event;
}main_trial;

trial{
	
	stimulus_event{		
		picture fixblack_pic;
		code = "ITI";
		duration = 2896;
	}post_event;
}mainITI_trial;


trial{
	all_responses = true;		#toggle to true for resp registration outside of trial
	stimulus_event{
		picture fixblack_pic;
		code = "blackfix1";
	}tactile_blackfix_event;
	stimulus_event{		
		picture fixred_pic;
		deltat = 296;
		duration = 280;
		code = "redfix";
	}tactile_redfix_event;
}tactile_prestim_trial;



text{caption=" ";max_text_width = 1200;}instruct_txt;

text{caption="waiting for experimenter";max_text_width = 1200;}waitexpr_txt;
text{caption="waiting for scanner";max_text_width = 1200;}wait_txt;
picture{text wait_txt;x=0;y=0;}wait_pic;

text{caption=" ";max_text_width = 1200;font_color = 255,200,200;background_color = 20,20,20;}warning;
picture{background_color = 20,20,20;text warning;x=0;y=0;}warning_pic;

text{caption="TOO SLOW";}slow_txt;
picture{text slow_txt;x=0;y=0;}slow_pic;

begin_pcl;

int subjectnr = int(logfile.subject());
if !(logfile.subject() == "") && subjectnr == 0 then exit("could not convert subjectnr to a positive integer");end;
int subjectcon = mod(subjectnr,8);
if subjectcon == 0 then subjectcon=8;end;
int mapping = subjectcon; if mapping > 5 then mapping = mapping - 4; end;

bool continuousLeft = true;
if mapping > 2 then continuousLeft = false; end;
bool facesLeft = true;
if mod(mapping,2) == 0 then facesLeft = false; end;

output_port outport = output_port_manager.get_port(1);		#LPT data I/O register, switches individual stims on/off
array <int> portcodes [8] = {1,2,4,8,16,32,64,128};

dio_device freq_ctrl = new dio_device(memory_dio_device,890,4); #LPT control I/O register, controls vibratory frequency
#value 890 is dec conversion from hexadecimal adress 0378, this is the I/O range for LPT port on adress D050 + 2 
#if LPT adress is different for your PC you should change this value

freq_ctrl.write(1,7);	#240 Hz

double scale_bmps = 0.57;
int eccentricity = 207;
int visual_stim_duration = 450;
int tactile_stim_duration = 450;
int slow_pic_duration = 1500;
int tactile_response_window = 750;

include "SimonTactile_subs.pcl";
include "SimonTactile_instructs.pcl";

loadtxt.set_caption("Loading");
array <bitmap> images [2][0];
images[1].assign(getBitmaps(stimulus_directory + "\\stims\\houses\\",".png",true));
images[2].assign(getBitmaps(stimulus_directory + "\\stims\\faces\\",".png",true));

images[1].shuffle();
images[2].shuffle();

array<int>VisStim_counters[2] = {0,0};

int nr_img_per_cat = images[1].count();
int nr_repeats = 1;
int nr_img_cats = 2;
int nr_of_trials = nr_repeats * nr_img_per_cat * nr_img_cats;


int nr_of_practice_trials = 16;


array<string>blockcon_V[] = {"Vis","Vis","Vis","Vis"};
array<string>blockcon_T[] = {"Tac","Tac","Tac","Tac"};
array<string>blockcon[0];

if subjectcon < 5 then
	blockcon.append(blockcon_V);
	blockcon.append(blockcon_T);
else
	blockcon.append(blockcon_T);
	blockcon.append(blockcon_V);
end;


array<int>trialcon[0];
trialcon.assign(advarrayfill(nr_of_trials,1,4));
trialcon.shuffle();


if file_exists(logfile_directory + logfile.subject()+"_SimonTact.txt") then	
	int resp3 = response_manager.total_response_count(3);
	int resp4 = response_manager.total_response_count(4);
	
	warning.set_caption("output file " + logfile.subject()+"_SimonTact.txt exists. It will be overwritten if you continue.\n\n\nPress space to proceed, ESC to abort." ,true);
	warning_pic.present();
	
	loop until false begin
		if resp3 < response_manager.total_response_count(3) then break;end;
		if resp4 < response_manager.total_response_count(4) then exit();end;
	end;
	
end;

	
out.open(logfile.subject()+"_SimonTact.txt");

if continuousLeft then out.print("continuous pulse mapped to left hand\n"); else out.print("continuous pulse mapped to right hand\n");end;
if facesLeft then out.print("faces mapped to left hand\n"); else out.print("faces mapped to right hand\n");end;

out.print("blocknr\tblockcon\ttrialnr\thouses\tcontinuous\trightStim\tVisStim_fn\tITI\tbutton\tRT\n");

array<int>ITI_durations [9] = {4000, 4500, 5000, 5500, 6000, 6500, 7000, 7500, 8000};
array<int>ITI_expcon[nr_of_trials];
ITI_expcon.assign(advarrayfill(nr_of_trials,1,9));

instruct_txt.set_caption(instruct1,true);
showInstruct_so(instruct_txt,200);

main_event.set_duration(visual_stim_duration-16-4);


######################################### block loop ########################
loop int b=1 until b>blockcon.count() begin
	
	bool practice = false;
	if blockcon[b].find("Pract")>0 then	practice = true;end;
	
	if blockcon[b].find("Vis")>0 then		
		instruct_txt.set_caption(instruct_vis2,true);
	else
		instruct_txt.set_caption(instruct_tac2,true);
	end;
	picture pic1 = showInstruct_so(instruct_txt,200);
	
	pic1.add_part(wait_txt,0,-400);
	
	#wait_pic.clear();
	#wait_pic.add_part(waitexpr_txt,0,0);
	#wait_pic.add_part(wait_txt,0,-200);
	pic1.present();
	
	ITI_expcon.shuffle();
	
	/*int resp3 = response_manager.total_response_count(3);
	loop until resp3 < response_manager.total_response_count(3) begin end;
	
	wait_pic.remove_part(1);
	wait_pic.present();
	*/
	
	int nr_pulses = pulse_manager.main_pulse_count();	
	loop until pulse_manager.main_pulse_count() > nr_pulses begin end;	

	######################################### trial loop ########################
	loop int t=1; until t>nr_of_trials begin
		
		bool houses = false;
		bool continuous = false;
		bool rightStim = false;
		bool slow = false;
		int button=0;
		int RT=0;
		
		if mod(trialcon[t],2)==0 then rightStim = true;end;
		
		stim_pic.clear();		
		stim_pic.add_part(fixblack_txt,0,0);
		int images_list_index=1;
		int current_ITI_duration=ITI_durations[ITI_expcon[t]];
		
		if blockcon[b].find("Vis")>0 then						
		#if mod(t,2)==1 then						
			
			if trialcon[t] < 3 then
				houses = true;
			end;
						
			if houses then
				main_event.set_event_code("house");
			else
				main_event.set_event_code("face");
				images_list_index=2;
			end;
		
			VisStim_counters[images_list_index]=VisStim_counters[images_list_index]+1;
			if VisStim_counters[images_list_index] > images[images_list_index].count() then
				VisStim_counters[images_list_index] = 1;
				images[images_list_index].shuffle();
			end;
						
			if !rightStim then
				stim_pic.add_part(images[images_list_index][VisStim_counters[images_list_index]],-eccentricity,0);
			else
				stim_pic.add_part(images[images_list_index][VisStim_counters[images_list_index]],eccentricity,0);
			end;
			
			post_event.set_duration(current_ITI_duration-(600+visual_stim_duration+16+4));
			
			##########################################	vis stim
			main_trial.present();
			##########################################
			
			stimulus_data stimdat = stimulus_manager.get_stimulus_data(stimulus_manager.stimulus_count());
			button=stimdat.button();
			RT=stimdat.reaction_time();
						
			if button == 0 then
				int resps = response_manager.total_response_count();			
				slow_pic.present();
				int slowstarttime = clock.time();
				logfile.add_event_entry("slow");
				wait_interval(slow_pic_duration - 4);
								
				if resps < response_manager.total_response_count() then	#a button was pressed during the slow message
					button = response_manager.get_response_data(resps+1).button();
					RT = (response_manager.get_response_data(resps+1).time() - slowstarttime)+visual_stim_duration;
				end;
				slow=true;
				post_event.set_duration(current_ITI_duration - (600+visual_stim_duration + slow_pic_duration + 16 + 4));
			end;
			
			###########################
			mainITI_trial.present();
			###########################
			
		else
			
			if trialcon[t] < 3 then
				continuous = true;
			end;			
			
			int outportcode = 1;						
			if rightStim then outportcode = 2;end;
			
			##########################################	tac stim
			tactile_prestim_trial.present();			
			
			stim_pic.present();			
			int stim_starttime = clock.time();
			#debug1_txt.set_caption(string(stim_starttime),true);
			
			int pulse_duration = tactile_stim_duration / 6;
			int cycle_duration = tactile_stim_duration / 3;
			
			int buttonpresses = response_manager.total_response_count();
			#debug2_txt.set_caption(string(buttonpresses),true);
			if continuous then				
				logfile.add_event_entry("continuous_pulse_start");
				outport.send_code(portcodes[outportcode],tactile_stim_duration);
				wait_interval(tactile_stim_duration);
			else
				logfile.add_event_entry("intermittent_pulse_start");
				outport.send_code(portcodes[outportcode],pulse_duration);
				wait_interval(cycle_duration);
				outport.send_code(portcodes[outportcode],pulse_duration);
				wait_interval(cycle_duration);
				outport.send_code(portcodes[outportcode],pulse_duration);
				wait_interval(cycle_duration);
			end;
			
			#fixblack_pic.present();
			logfile.add_event_entry("ITI1");
			int ITI1_duration = tactile_response_window - tactile_stim_duration;
			wait_interval(ITI1_duration - 4);
						
			int tactile_ITI_duration = current_ITI_duration - (600 + tactile_response_window +  4);
			
			if response_manager.total_response_count() > buttonpresses then
				button = response_manager.get_response_data(buttonpresses+1).button();
				RT = response_manager.get_response_data(buttonpresses+1).time() - stim_starttime;
				
				
				#debug3_txt.set_caption(string(RT),true);
				
				/*term.print_line("stim_starttime:" + string(stim_starttime));
				term.print_line("clocktime:" + string(clock.time()));
				term.print_line("resps:" + string(response_manager.total_response_count()));
				loop int x=1 until x>response_manager.total_response_count() begin
					term.print_line("resp" + string(x) + " - " +  string(response_manager.get_response_data(x).time()) + " - " + string(response_manager.get_response_data(x).button()));
					x=x+1;
				end;
				term.print_line("resp" + string(response_manager.get_response_data(buttonpresses+1).time()));
				term.print_line("\n"); */
			else		
				slow_pic.present();
				int slowstarttime = clock.time();
				logfile.add_event_entry("slow");
				wait_interval(slow_pic_duration - 4);
								
				if response_manager.total_response_count() > buttonpresses then	#a button was pressed during the slow message
					button = response_manager.get_response_data(buttonpresses+1).button();
					RT = (response_manager.get_response_data(buttonpresses+1).time() - slowstarttime)+tactile_stim_duration;
				end;
				tactile_ITI_duration = tactile_ITI_duration - slow_pic_duration;			
				slow=true;	
			end;
			
			fixblack_pic.present();
			logfile.add_event_entry("ITI2");
			wait_interval(tactile_ITI_duration);
			
			##########################################
			
		end;
		
		writi(b);
		write(blockcon[b]);
		writi(t);
		if blockcon[b].find("Vis")>0 then 
			write(string(houses));
			write(" ");
			write(string(rightStim));
			write(removepath(images[images_list_index][VisStim_counters[images_list_index]].filename()));
		else
			write(" ");
			write(string(continuous));
			write(string(rightStim));
			write(" ");
		end;
		writi(current_ITI_duration);
		
		writi(button);
		writi(RT);
		if slow then write("slow");end;
		out.print("\n");
		
		t=t+1;
		if practice && t>nr_of_practice_trials then break;end;
		
	end;
	
	b=b+1;
end;




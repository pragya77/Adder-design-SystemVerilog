 
 `timescale 1ns/100ps 

 interface intf();	
	logic reset;
	logic [7:0] in1;
	logic [7:0] in2;
	logic [7:0] sum;
	logic carry;
 endinterface

 interface clk_if();
 	logic tb_clk;
	initial tb_clk =0;
	always #10 tb_clk = ~tb_clk;
 endinterface

 class packet;

	rand bit reset;
	rand bit [7:0] in1;
	rand bit [7:0] in2;
	bit [7:0] sum;
	bit carry;

 	function void print ();
		$display (" The packet consists of in1= %0h, in2=  %0h, sum= %0h and 		carry= %0h", in1, in2, sum, carry);
	endfunction
   
   	function void copy( packet tmp);
    	this.in1 = tmp.in1;
      	this.in2 = tmp.in2;
      	this.reset = tmp.reset;
      	this.sum = tmp.sum;
      	this.carry = tmp.carry;
   	endfunction 

	constraint in { in1 > 100 ; in1 < 200 ; }
	constraint rst { reset dist { 1:= 30 , 0:= 70 } ; }

 endclass

 class scoreboard;
	mailbox mon_m;

	task run();
		forever begin 
			packet item; 
          	packet ref_item;
			mon_m.get(item);

			ref_item = new();
			ref_item.copy(item);

			if(!ref_item.reset)
			{ref_item.sum, ref_item.carry} = ref_item.in1 + ref_item.in2;
			else
			{ref_item.sum, ref_item.carry} = 0;

          if(ref_item.sum != item.sum && ref_item.carry != item.sum)begin
            $display("Scoreboard Error, ref_item carry = %0h, item carry = %0h, ref_item sum = %0h, item sum = %0h", ref_item.carry, item.carry, ref_item.sum, item.sum);
			end
			else begin
              $display("Scoreboard Pass, ref_item carry = %0h, item carry = %0h, ref_item sum = %0h, item sum = %0h", ref_item.carry, item.carry, ref_item.sum, item.sum);
			end
		end
	endtask
 endclass

 class monitor;
	
	virtual intf inf;
	virtual clk_if i_clk_if;
	mailbox mon_m;
	
	task run();
	forever begin
		packet m_item = new();
		@(posedge i_clk_if.tb_clk);
		m_item.in1 = inf.in1;
		m_item.in2 = inf.in2;
		m_item.reset = inf.reset;
		m_item.sum = inf.sum;
		m_item.carry = inf.carry;
		mon_m.put(item);
	end
	endtask

 endclass

 class generator;
	
	mailbox drv_m;

	task run();
		for( int i = 0; i<=20; i++) begin 
			packet item = new;
			item.randomize();
			drv_m.put(item);
		end
	endtask
 endclass
   
class driver;

	virtual intf inf;
	virtual clk_if i_clk_if;
	mailbox drv_m;

  	task run();
		$display("driver");
		forever begin
			packet item;
			drv_m.get(item);
          @(posedge i_clk_if.tb_clk);
			inf.reset <= item.reset;
			inf.in1 <= item.in1;
			inf.in2 <= item.in2;
		end
	endtask
 endclass

 class env;
	driver i_driver;
	generator i_generator;
	monitor i_monitor;
	scoreboard i_scoreboard;

	mailbox drv_m;
	mailbox mon_m;
	
	virtual intf inf;
	virtual clk_if i_clk_if;

	function new();
		i_driver = new;
		i_monitor = new;
		i_generator = new;
		i_scoreboard = new;
		drv_m = new;
		mon_m = new;
	endfunction

	virtual task run();
		i_driver.inf = inf;
		i_monitor.inf = inf;
		i_driver.i_clk_if = i_clk_if;
		i_monitor.i_clk_if = i_clk_if;
	
		i_driver.drv_m = drv_m;
		i_generator.drv_m = drv_m;

		i_monitor.mon_m = mon_m;
		i_scoreboard.mon_m = mon_m;

		fork 
			i_driver.run();
			i_monitor.run();
			i_generator.run();
			i_scoreboard.run();
		join_any
	endtask
 endclass

class test;
	env i_env;
	
	function new();
		i_env = new();
	endfunction

	virtual task run();
		i_env.run();
	endtask
 endclass

 module tb;
	intf inf ();
	clk_if i_clk_if ();

	adder i_adder(inf);
 	
	initial begin
      	test i_test ;
      	i_test = new;
		i_test.i_env.inf = inf;
		i_test.i_env.i_clk_if = i_clk_if;
		i_test.run();

		#440 $finish;
	end
	initial begin
	$dumpvars;
	$dumpfile("dump.vcd");
	end
	
 endmodule
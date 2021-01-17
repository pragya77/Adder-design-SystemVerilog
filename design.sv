`timescale 1ns/100ps 
 module adder( intf inf);

	always_comb
	begin
		if(inf.reset) 
		begin
			inf.sum <= 0;
			inf.carry <=0;
		end
		else 
		begin
		{ inf.sum, inf.carry } = inf.in1 + inf.in2;
		end
	end

 endmodule
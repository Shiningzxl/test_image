

module test_image # (
	parameter	SENSOR_DAT_WIDTH	= 10	,	
	parameter	CHANNEL_NUM			= 4			
	)
	(
	//
	input											clk					,	
	input											i_fval				,	
	input											i_lval				,	////
	input	[SENSOR_DAT_WIDTH*CHANNEL_NUM-1:0]		iv_pix_data			,	
	
	input	[2:0]									iv_test_image_sel	,	
	
	output											o_fval				,	
	output											o_lval				,	
	output	[SENSOR_DAT_WIDTH*CHANNEL_NUM-1:0]		ov_pix_data				
	);

	
	reg												fval_dly			= 1'b0;	//////sss
	wire											fval_fall			;
	reg												lval_dly			= 1'b0;
	wire											lval_fall			;
	reg		[7:0]									frame_cnt			= 8'b0;
	reg		[7:0]									line_cnt			= 8'b0;
	reg		[7:0]									col_cnt				= 8'b0;
	reg		[SENSOR_DAT_WIDTH*CHANNEL_NUM-1:0]		pix_data_reg		= {(SENSOR_DAT_WIDTH*CHANNEL_NUM){1'b0}};


	always @ (posedge clk) begin
		fval_dly	<= i_fval;
	end
	assign	fval_fall	= (fval_dly==1'b1 && i_fval==1'b0) ? 1'b1 : 1'b0;

	
	always @ (posedge clk) begin
		if(i_fval) begin
			lval_dly	<= i_lval;
		end
		else begin
			lval_dly	<= 1'b0;
		end
	end
	assign	lval_fall	= (lval_dly==1'b1 && i_lval==1'b0) ? 1'b1 : 1'b0;

	
	always @ (posedge clk) begin
		case(iv_test_image_sel)
			3'b000,3'b001,3'b110	: frame_cnt	<= 8'b0;
			3'b010	: begin
				if(fval_fall) begin
					frame_cnt	<= frame_cnt + 8'b1;
				end
			end
			default	: frame_cnt	<= 8'b0;
		endcase
	end

	
	always @ (posedge clk) begin
		case(iv_test_image_sel)
			3'b000,3'b001	: line_cnt	<= frame_cnt;
			3'b110,3'b010	: begin
				if(!i_fval) begin
					line_cnt	<= frame_cnt;
				end
				else begin
					if(lval_fall) begin
						line_cnt	<= line_cnt + 8'b1;
					end
				end
			end
			default		: line_cnt	<= frame_cnt;
		endcase
	end

	
	always @ (posedge clk) begin
		case(iv_test_image_sel)
			3'b000	: col_cnt	<= line_cnt;
			3'b001	: begin
				if(fval_fall) begin
					col_cnt	<= col_cnt + 8'b1;
				end
			end
			3'b110,3'b010	: begin
				if(i_fval&i_lval) begin
					col_cnt	<= col_cnt + CHANNEL_NUM;
				end
				else begin
					col_cnt	<= line_cnt;
				end
			end
			default		: col_cnt	<= line_cnt;
		endcase
	end



	generate
		genvar k;
		for( k = 0 ; k < CHANNEL_NUM ; k = k + 1 )
			begin
				always @ (posedge clk) begin
					if(i_fval==1'b1 && i_lval==1'b1) begin
						if(iv_test_image_sel==3'b000) begin
							pix_data_reg[SENSOR_DAT_WIDTH*(k+1)-1 : SENSOR_DAT_WIDTH*k]	<= iv_pix_data[SENSOR_DAT_WIDTH*(k+1)-1 : SENSOR_DAT_WIDTH*k];
						end
						else if (iv_test_image_sel==3'b001) begin
							pix_data_reg[SENSOR_DAT_WIDTH*(k+1)-1 : SENSOR_DAT_WIDTH*k]	<= {col_cnt,{(SENSOR_DAT_WIDTH-8){1'b0}}};
						end
						else begin
							pix_data_reg[SENSOR_DAT_WIDTH*(k+1)-1 : SENSOR_DAT_WIDTH*k]	<= {(col_cnt+k),{(SENSOR_DAT_WIDTH-8){1'b0}}};
						end
					end
					else begin
						pix_data_reg[SENSOR_DAT_WIDTH*(k+1)-1 : SENSOR_DAT_WIDTH*k]	<= {(SENSOR_DAT_WIDTH){1'b0}};
					end
				end
			end
	endgenerate

	
	assign	ov_pix_data			= pix_data_reg;
	assign	o_fval				= fval_dly;
	assign	o_lval				= lval_dly;




endmodule

module decoder_3to8b(
  input[2:0] in,
  output[7:0] out);

  assign out =  (in == 3'd0) ? 8'h01:
                (in == 3'd1) ? 8'h02:
                (in == 3'd2) ? 8'h04:
                (in == 3'd3) ? 8'h08:
                (in == 3'd4) ? 8'h10:
                (in == 3'd5) ? 8'h20:
                (in == 3'd6) ? 8'h40:
                (in == 3'd7) ? 8'h80:
                8'h0;
endmodule
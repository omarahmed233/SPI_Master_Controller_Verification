`ifndef SPI_DUT_WRAPPER_SVH
    `define SPI_DUT_WRAPPER_SVH
`timescale 1ns/1ps

module dut_wrapper (
    apb_master_ifc apb,
    spi_slave_ifc spi
);

    spi_master u_dut (
        .PCLK    (apb.pclk),
        .PRESETn (apb.presetn),
        .PSEL    (apb.psel),
        .PENABLE (apb.penable),
        .PWRITE  (apb.pwrite),
        .PADDR   (apb.paddr),
        .PWDATA  (apb.pwdata),
        .PRDATA  (apb.prdata),
        .PREADY  (apb.pready),
        .PSLVERR (apb.pslverr),
        .SCLK    (spi.sclk),
        .MOSI    (spi.mosi),
        .MISO    (spi.miso),
        .SS_n    (spi.ss_n),
        .IRQ     (apb.irq)
    );

endmodule

`endif
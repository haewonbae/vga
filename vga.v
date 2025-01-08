library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

entity vga_controller is
    Port ( clk       : in  STD_LOGIC;       -- FPGA時鐘
           rst_n     : in  STD_LOGIC;       -- 重置信號
           hsync     : out STD_LOGIC;       -- 水平同步信號
           vsync     : out STD_LOGIC;       -- 垂直同步信號
           red       : out STD_LOGIC_VECTOR (3 downto 0);  -- 紅色顏色分量
           green     : out STD_LOGIC_VECTOR (3 downto 0);  -- 綠色顏色分量
           blue      : out STD_LOGIC_VECTOR (3 downto 0)   -- 藍色顏色分量
           );
end vga_controller;

architecture Behavioral of vga_controller is
    -- VGA參數定義 (640x480解析度，60Hz刷新率)
    constant H_SYNC_CYCLES : integer := 96;  -- 水平同步脈寬
    constant H_BACK_PORCH : integer := 48;   -- 水平後座標
    constant H_ACTIVE_VIDEO : integer := 640; -- 顯示區寬度
    constant H_FRONT_PORCH : integer := 16;  -- 水平前座標
    constant V_SYNC_CYCLES : integer := 2;   -- 垂直同步脈寬
    constant V_BACK_PORCH : integer := 33;   -- 垂直後座標
    constant V_ACTIVE_VIDEO : integer := 480; -- 顯示區高度
    constant V_FRONT_PORCH : integer := 10;  -- 垂直前座標

    signal divclk: STD_LOGIC_VECTOR(1 downto 0);  -- 分頻時鐘
    signal fclk: STD_LOGIC;  -- 像素時鐘 (分頻後的時鐘)
    signal h_count : integer range 0 to 799 := 0;  -- 水平計數器
    signal v_count : integer range 0 to 524 := 0;  -- 垂直計數器
begin
    -- 水平計數器和垂直計數器
    process(fclk, rst_n)
    begin
        if rst_n = '0' then
            h_count <= 0;
            v_count <= 0;
        elsif rising_edge(fclk) then
            if h_count = 799 then
                h_count <= 0;
                if v_count = 524 then
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;

    -- 水平同步信號和垂直同步信號
    hsync <= '0' when (h_count < H_SYNC_CYCLES) else '1';
    vsync <= '0' when (v_count < V_SYNC_CYCLES) else '1';

    -- 顯示顏色設定
    process(fclk, rst_n)
    begin
        if rst_n = '0' then
            red   <= "0000"; -- 默認為黑色
            green <= "0000";
            blue  <= "0000";
        elsif rising_edge(fclk) then
            -- 背景區域為黑色
            red   <= "0000";
            green <= "0000";
            blue  <= "0000";

       
      
            if ( (h_count-450 ) * (h_count-450 ) + (v_count - 200) * (v_count - 200) <= 150 * 150 ) then
                    red   <= "1111";  -- 紅色分量
                    green <= "0011";  -- 綠色圓形
                    blue  <= "0000";  -- 藍色分量
                end if;
            end if;
    end process;

    -- 時鐘分頻: 從 FPGA 的 clk (100 MHz) 生成像素時鐘 (25.175 MHz)
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            divclk <= (others => '0');
        elsif rising_edge(clk) then
            divclk <= divclk + 1;
        end if;
    end process fd;
    fclk <= divclk(1);  -- 使用分頻後的時鐘作為像素時鐘
end Behavioral;

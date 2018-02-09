library(ggplot2)
theme_set(theme_bw(base_size = 14))

stderror <- function(x) sd(x)/sqrt(length(x))

# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

cbPalette <- c("#a1d99b", "#9ecae1", "#31a354", "#3182bd")

plot_generic <- function(in_df, in_xfield, in_xlab, in_commonlab, show_legend=FALSE, show_ylabel=FALSE, in_ylim=25, legend_pos="left") {
  in_df$variant_zthread <- gsub('-2', ', 1 thread', in_df$variant_zthread)
  in_df$variant_zthread <- gsub('-3', ', 2 threads', in_df$variant_zthread)
  in_df$variant_zthread <- factor(in_df$variant_zthread, levels = c("sgx, 1 thread", "vanilla, 1 thread", "sgx, 2 threads", "vanilla, 2 threads"))
  
  p = ggplot(in_df, aes_string(in_xfield, "percent_dropped", fill="variant_zthread")) +
    geom_bar(stat="identity", colour="black", position="dodge") +
    ylim(0,in_ylim) + ylab("Packets dropped (%)") +
    xlab(in_xlab) +
    theme(legend.title=element_blank()) +
    scale_fill_manual(values=cbPalette)
  if (legend_pos == "left") {
    p = p + theme(legend.justification=c(0.05,0.98), legend.position=c(0.05,0.98))
  }
  else {
    p = p + theme(legend.justification=c(0.95,0.98), legend.position=c(0.95,0.98))
  }
  if (show_legend == FALSE) {
    p = p + theme(legend.position="none")
  }
  if (show_ylabel == FALSE) {
    p = p + theme(axis.title.y=element_blank())
  }
  return(p)
}
  
plot_pktsize <- function(in_df, in_num_flows=256, in_num_rules=0, prefix="", show_legend=FALSE, show_ylabel=FALSE) {
  df = subset(in_df, in_df$snortconfig=="snort.lua" & in_df$snortalert=="" & in_df$pktgenpcap=="" & 
                   in_df$num_flows==in_num_flows & in_df$num_rules==in_num_rules)
  xlabel = paste(prefix, " # flows=", in_num_flows, ", # rules=", in_num_rules, sep="")
  return(plot_generic(df, "factor(pkt_size)", xlabel, "Packet size", show_legend, show_ylabel))
}

plot_numflows <- function(in_df, in_pkt_size=64, in_num_rules=0, prefix="", show_legend=FALSE, show_ylabel=FALSE) {
  df = subset(in_df, in_df$snortconfig=="snort.lua" & in_df$snortalert=="" & in_df$pktgenpcap=="" & 
                in_df$pkt_size==in_pkt_size & in_df$num_rules==in_num_rules)
  xlabel = paste(prefix, " pkt size=", in_pkt_size, "B, # rules=", in_num_rules, sep="")
  return(plot_generic(df, "factor(num_flows)", xlabel, "Number of flows", show_legend, show_ylabel))
}

plot_numrules <- function(in_df, in_num_flows=256, in_pkt_size=64, prefix="", show_legend=FALSE, show_ylabel=FALSE) {
  df = subset(in_df, in_df$snortconfig=="snort.lua" & in_df$snortalert=="" & in_df$pktgenpcap=="" & 
                in_df$num_flows==in_num_flows & in_df$pkt_size==in_pkt_size)
  xlabel = paste(prefix, " # flows=", in_num_flows, ", pkt size=", in_pkt_size, "B", sep="")
  return(plot_generic(df, "factor(num_rules)", xlabel, "Number of rules", show_legend, show_ylabel))
}

plot_snortconfig <- function(in_df, in_snortconfig="", prefix="", show_legend=FALSE, show_ylabel=FALSE) {
  df = subset(in_df, in_df$snortconfig==in_snortconfig & in_df$snortalert=="" & in_df$pktgenpcap=="" & 
                in_df$num_flows==32000 & in_df$num_rules==0)
  if (in_snortconfig == "") {
    xlabel = " w/o"
  } else {
    xlabel = " w/"
  }
  xlabel = paste(prefix, xlabel, ", # flows=32000, # rules=0", sep="")
  return(plot_generic(df, "factor(pkt_size)", xlabel, "Packet size", show_legend, show_ylabel))
}

plot_snortalert <- function(in_df, in_snortalert="", prefix="", show_legend=FALSE, show_ylabel=FALSE) {
  df = subset(in_df, in_df$snortconfig=="snort.lua" & in_df$snortalert==in_snortalert & in_df$pktgenpcap=="" & 
                in_df$num_flows==32000 & in_df$num_rules==3462)
  if (in_snortalert == "") {
    xlabel = " w/o"
  } else {
    xlabel = " w/"
  }
  xlabel = paste(prefix, xlabel, ", # flows=32000, # rules=3462", sep="")
  return(plot_generic(df, "factor(pkt_size)", xlabel, "Packet size", show_legend, show_ylabel))
}

plot_pcap <- function(in_df, in_pktgenpcap="", prefix="", show_legend=FALSE, show_ylabel=FALSE) {
  df = subset(in_df, in_df$snortconfig=="snort.lua" & in_df$snortalert=="" & in_df$pktgenpcap==in_pktgenpcap)
  xlabel = paste(prefix, " # flows=", df$num_flows[1], ", pkt size=", df$pkt_size[1], "B", sep="")
  return(plot_generic(df, "factor(num_rules)", xlabel, "Number of rules", show_legend, show_ylabel))
}

# ----------------------
setwd("final")
dir.create("fig", showWarnings=F)
df = read.table('exp-all.csv',header=T,sep=',')

df$percent_dropped = df$rx_priority0_dropped / df$rx_total_packets * 100
df$percent_analyzed = df$daq_analyzed / df$daq_received * 100
df$timing_mpps = df$timing_pps / 1000.0 / 1000.0
df$daq_percent_received = df$daq_received/df$rx_total_packets * 100
df$mbps_received = df$timing_mpps * df$pkt_size * 8
df$mpps_analyzed = df$timing_mpps * df$percent_analyzed / 100
df$mbps_analyzed = df$mpps_analyzed * df$pkt_size * 8

dferr = aggregate(percent_dropped ~ variant + sleep + zthread + pktgenconfig + pktgenpcap + snortconfig + snortrule + snortalert + pkt_size + num_flows + num_rules + variant_zthread, data=df, FUN = function(x) c(mean = mean(x), se = stderror(x)))
dferr <- do.call(data.frame, dferr)
dferr$percent_dropped.sepercent = dferr$percent_dropped.se / dferr$percent_dropped.mean * 100

df = aggregate(. ~ variant + sleep + zthread + pktgenconfig + pktgenpcap + snortconfig + snortrule + snortalert + pkt_size + num_flows + num_rules + variant_zthread, data=df, mean)
df <- do.call(data.frame, df)

pdf("fig/11_dropped_pktsize.pdf", width=15, height=3) 
p0 = plot_pktsize(df, in_num_flows=256,   in_num_rules=0,    prefix="(a)", show_legend=TRUE, show_ylabel=TRUE)
p1 = plot_pktsize(df, in_num_flows=32000, in_num_rules=0,    prefix="(b)")
p2 = plot_pktsize(df, in_num_flows=256,   in_num_rules=3462, prefix="(c)")
p3 = plot_pktsize(df, in_num_flows=32000, in_num_rules=3462, prefix="(d)")
multiplot(p0, p1, p2, p3, cols=4)
dev.off()

pdf("fig/12_dropped_numflows.pdf", width=15, height=3) 
p0 = plot_numflows(df, in_pkt_size=64,   in_num_rules=0,     prefix="(a)", show_legend=TRUE, show_ylabel=TRUE)
p1 = plot_numflows(df, in_pkt_size=1024, in_num_rules=0,     prefix="(b)")
p2 = plot_numflows(df, in_pkt_size=64,   in_num_rules=3462,  prefix="(c)")
p3 = plot_numflows(df, in_pkt_size=1024, in_num_rules=3462,  prefix="(d)")
multiplot(p0, p1, p2, p3, cols=4)
dev.off()

pdf("fig/13_dropped_numrules.pdf", width=15, height=3) 
p0 = plot_numrules(df, in_num_flows=256,   in_pkt_size=64,   prefix="(a)", show_legend=TRUE, show_ylabel=TRUE)
p1 = plot_numrules(df, in_num_flows=32000, in_pkt_size=64,   prefix="(b)")
p2 = plot_numrules(df, in_num_flows=256,   in_pkt_size=1024, prefix="(c)")
p3 = plot_numrules(df, in_num_flows=32000, in_pkt_size=1024, prefix="(d)")
multiplot(p0, p1, p2, p3, cols=4)
dev.off()

pdf("fig/14_dropped_config.pdf", width=8, height=3)
p0 = plot_snortconfig(df, in_snortconfig="",          prefix="(a)", show_legend=TRUE, show_ylabel=TRUE)
p1 = plot_snortconfig(df, in_snortconfig="snort.lua", prefix="(b)")
multiplot(p0, p1, cols=2)
dev.off()

pdf("fig/15_dropped_alert.pdf", width=8, height=3)
p0 = plot_snortalert(df, in_snortalert="",     prefix="(a)", show_legend=TRUE, show_ylabel=TRUE)
p1 = plot_snortalert(df, in_snortalert="fast", prefix="(b)")
multiplot(p0, p1, cols=2)
dev.off()

pdf("fig/16_dropped_pcap.pdf", width=15, height=3) 
p0 = plot_pcap(df, in_pktgenpcap="test.pcap", prefix="(a) test: ", show_legend=TRUE, show_ylabel=TRUE)
p1 = plot_pcap(df, in_pktgenpcap="smallFlows.pcap", prefix="(b) small: ")
p2 = plot_pcap(df, in_pktgenpcap="bigFlows.pcap", prefix="(c) big: ")
multiplot(p0, p1, p2, cols=3)
dev.off()

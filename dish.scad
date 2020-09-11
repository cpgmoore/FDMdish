//Auth  CPGMoore
//Src   http://www.github.com/cpgmoore/FDMdish
//Lic	MIT

/* Hints:
Typical print volumes for low cost 3d printers are in the order of 200^3 to 300^3
The tiles here are dimensioned to fill the max build volume of the available printer
Expected extrusion width is 1mm (0.8mm nozzle)
Material must be low warp, PLA/PETG are ideal candidates
Typical overhang limits for agressive layer heights are to not exceed 45deg
This limit is met when the focal length is approximately equiv. to half the total assembled panel width
eg: 
    2 panels wide, 200mm/panel = 400mm wide, focal length should be 200mm
    4 panels wide, 200mm/panel = 800mm wide, focal length should be 400mm
    2 panels wide, 300mm/panel = 600mm wide, focal length should be 300mm
    4 panels wide, 300mm/panel = 1200mm wide, focal length should be 600mm
*/


/* [Paraboloid] */
show_paraboloid=false;
show_focal_point=false;
paraboloid_focal_length_mm=250;
paraboloid_surface_thickness_mm=5.0;

/* [Supports] */
show_plane=false;
//This is the depth below the XY plane, with a surface thickness of 5mm, 25mm gives 20mm of clearance behind the paraboloid volume
plane_offset_z_mm=-25;
//CAUTION: experimental feature, adjusts the support plane to allow for a greater range of off axis arrangements
plane_rotate_x_deg=0;
show_supports = false;
//Ideally twice the 3D print process line width
support_thickness_mm=2;
paraboloid_limit_z_mm=400;

//A distance of 10mm between the internal support surface and the ideal edge of a tile, allows 20x20mm extrustion as a rigid support between tiles
support_edge_offset_mm=10;
//Support holes allow the tile to be bolted to the extrusion support beam, square holes are computationally cheaper
support_holes_mm = 5.0;


//the tile is located in the XY plane,
//Then the plane is rotated
//Rotation of the plane is somewhat experimental
//And is intended for off axis reflectors of angles approx ~ 90deg
//The angle should be experimented with the produce parts that can be reliably printed by the FDM process
/* [Printable Tile] */
show_tile_mask = false;
show_tile_masked_shell=true;
show_tile_masked_support=true;
tile_dim_mm=200;
tile_location_x=100.0;
tile_location_y=100.0;
tile_edge_clearance_mm=1.0;
//Alignment guides provide a reference point for locating mirrors at regular intervals. This would allow fine tuning of mounted positions for better focus.
enable_alignment_guides = true;
show_alignment_guides = false;
alignment_guide_dim_mm=1.0; //



//A paraboloid is defined as following the equation:
// y = x^2/(4*focal length)


//The following allows us to constrain construction of the paraboloid for improved efficiency, using worst case orientation of tile
//These functions are not rigourously derived rocket science, and contain some additional fudging and safety factors
tile_center_to_vertex=tile_dim_mm/2.0*sqrt(2);
paraboloid_radius_max_mm=round(sqrt(pow(tile_location_x,2)+pow(tile_location_y,2))+tile_center_to_vertex) + 200; //+200 to fudge in the experimental features
//paraboloid_radius_min_mm=sqrt(pow(tile_location_x,2)+pow(tile_location_y,2))-tile_center_to_vertex;
//paraboloid_radius_max_mm=500;

module 2D_paraboloid_shell_slice(focal_length,radius, thickness_offset_y, N_segments){
	//http://forum.openscad.org/2dgraph-equation-based-2-D-shapes-in-openSCAD-td15722.html
    interval=radius/N_segments;
    //more complicated than it needs to be, but avoids problems with floating points and thin shells
    x_set_for=[for(x = [0:interval:radius]) x ];
    x_set_rev=[for(i = [len(x_set_for)-1:-1:0]) x_set_for[i]];
    
	polygon(points=concat(
        //reference surface, starting centre
        [for(x=x_set_for)
            [x,(x*x)/(4*focal_length)]	],
        //Offset surface, starting at edge
        [for(x=x_set_rev)
            [x,(x*x)/(4*focal_length)+thickness_offset_y]	]
	));
}
//2D_paraboloid_shell_slice(250,250,-5,10);

module 3D_paraboloid_shell(focal_length,radius, thickness_z){
	rotate_segment_angle_deg=2;

    rotate_extrude(angle=360, convexity=1,$fa=rotate_segment_angle_deg){
        segment_length_mm=5.0;
        
        N_segments=ceil(radius/segment_length_mm);
        2D_paraboloid_shell_slice(focal_length,radius,thickness_z,N_segments);
    }
}
//3D_paraboloid_shell(250,500,5);

module 2D_paraboloid_slice(focal_length,radius,limit_y,N_segments){
	//http://forum.openscad.org/2dgraph-equation-based-2-D-shapes-in-openSCAD-td15722.html
    interval=radius/N_segments;
    //interval=10;
	polygon(points=concat(
                            //Paraboloid surface, starting centre
                            [for(x=[0:interval:radius])
                                [x,(x*x)/(4*focal_length)]	],
                            //Take it to the limit, then back to the center at the limit
                            [[radius,limit_y], [0,limit_y]]
	));
}
//2D_paraboloid_slice(100,100,1000,10);

module 3D_paraboloid(focal_length, radius, limit_z){
	rotate_segment_angle_deg=2;
    
    rotate_extrude(angle=360, convexity=1,$fa=rotate_segment_angle_deg){
        segment_length_mm=5.0;
        
        N_segments=ceil(radius/segment_length_mm);
        2D_paraboloid_slice(focal_length,radius,limit_z, N_segments);
    }
}
//3D_paraboloid(250,500,1000);


//******************************************************************************



module shell(){
    3D_paraboloid_shell(paraboloid_focal_length_mm, paraboloid_radius_max_mm,-paraboloid_surface_thickness_mm);

}



//******************************************************************************



module fastener_negative(wall_thickness){
    translate([0,0,10]){
        //A cube is cheaper than a cylinder, and functionally the same result for a cylindrical fastener
        cube(size=[wall_thickness,support_holes_mm,support_holes_mm],center=true); 
    }
}
//fastener_M3_negative(10);

module single_support(){
    difference(){
        
        wall_depth=paraboloid_limit_z_mm-plane_offset_z_mm;
        wall_offset=wall_depth/2+plane_offset_z_mm;
        
        
        //translate([0,0,wall_offset]){
        difference(){
            translate([0,0,wall_depth/2]){
                cube(size=[support_thickness_mm,tile_dim_mm,wall_depth],center=true);
            }
            
            for(y=[-80:20:+80]){
                translate([0,y,0]){
                    fastener_negative(support_thickness_mm+1);
                }
            }
        }
    }
}
//single_support();

module label_params(){

    text_size=10;
    translate([0,10,0]){
        text(str("f=", paraboloid_focal_length_mm, " dim=",tile_dim_mm," pos=(", tile_location_x,",", tile_location_y,")"),halign="center",valign="center",size=text_size);
    }
}

module label_source(){

    text_size=10;
    translate([0,10,0]){
        //alternatives: FDMdish print-a-dish
        text("github.com/cpgmoore/FDMdish",halign="center",valign="center",size=text_size);
    }
}

module label_support_params(){
    translate([support_thickness_mm/2-0.5,0,10]){
        rotate(a = 90, v=[0, 1, 0]){
            rotate(a = 90, v=[0, 0, 1]){
                linear_extrude(height = 1.0){
                    label_params();
                }           
            }
        }
    }
}
// support_label();

module label_support_source(){
    translate([-support_thickness_mm/2+0.5,0,10]){
        rotate(a = -90, v=[0, 1, 0]){
            rotate(a = -90, v=[0, 0, 1]){
                linear_extrude(height = 1.0){
                    label_source();
                }           
            }
        }
    }
}

module supports(){  
    tile_edge=tile_dim_mm/2;
    support_center_offset=tile_edge-support_edge_offset_mm-support_thickness_mm/2;
    translate([-support_center_offset,0,0]){
        single_support();
        label_support_params();
    }
    
    translate([support_center_offset,0,0]){
        single_support();
        label_support_source();
    }
}
//supports();

module support_tile(){
    difference(){
        rotate(a=plane_rotate_x_deg, v=[1,0,0]){
            translate([tile_location_x,tile_location_y,plane_offset_z_mm]){
                supports();
            }
        }
        3D_paraboloid(paraboloid_focal_length_mm, paraboloid_radius_max_mm, 2*paraboloid_focal_length_mm);
    }
}


//******************************************************************************


module focal_point(){
    translate([0,0,paraboloid_focal_length_mm]){
        sphere(10);
    }
}

module plane(){
    rotate(a=plane_rotate_x_deg,v=[1,0,0]){
        translate([0,0,plane_offset_z_mm-1]){
            cube(size=[2000,2000,1], center=true);
        }
    }
}

module alignment_guides(){
    
    offset=tile_dim_mm/4;
    height=500;
    for(x=[-offset,+offset]){
        for(y=[-offset,+offset]){
            translate([tile_location_x+x,tile_location_y+y,0]){
                    cube(size=[alignment_guide_dim_mm,alignment_guide_dim_mm,height],center=true);
            }
        }
    }
}


//******************************************************************************


module tile_mask(){
    cube_height=paraboloid_focal_length_mm-plane_offset_z_mm; //+200 to fudge in experimental features
    cube_bottom=-cube_height/2;
    rotate(a=plane_rotate_x_deg,v=[1,0,0]){
        translate([tile_location_x,tile_location_y,-cube_bottom+plane_offset_z_mm]){
            cube([tile_dim_mm-tile_edge_clearance_mm,tile_dim_mm-tile_edge_clearance_mm,cube_height],center=true);

        }
    }
}
//tile_mask();

module tile_masked_support(){
    intersection(){
        tile_mask();
        support_tile();
    }
    
}
//tile_masked_support();

module tile_masked_shell(){
    intersection(){
        tile_mask();
        difference(){
            shell();
            if(enable_alignment_guides){
                alignment_guides();
            }
        }
    } 
}
//tile_masked_shell();


//******************************************************************************


//Optional display/debug/render/export components:
module render_list(){


    if(show_paraboloid){
        shell();
    }

    if(show_supports){
        supports();
    }

    if(show_plane){
        plane();
    }



    if(show_alignment_guides){
        alignment_guides();
    }

    if(show_focal_point){
        focal_point();
    }
    
    
    
    if(show_tile_mask){
        tile_mask();
    }

    if(show_tile_masked_shell){
        tile_masked_shell();
    }
    
    if(show_tile_masked_support){
        tile_masked_support();
    }
    
}


render_list();



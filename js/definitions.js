var config = {

  tagline: "The Laboratory</br>Operating System",
  documentation_url: "http://localhost:4000/aquarium",
  title: "Primer Workflow",
  navigation: [

    {
      category: "Overview",
      contents: [
        { name: "Introduction", type: "local-md", path: "README.md" },
        { name: "About this Workflow", type: "local-md", path: "ABOUT.md" },
        { name: "License", type: "local-md", path: "LICENSE.md" },
        { name: "Issues", type: "external-link", path: 'https://github.com/klavinslab/primer-workflow/issues' }
      ]
    },

    

      {

        category: "Operation Types",

        contents: [

          
            {
              name: 'Make Primer Aliquot',
              path: 'operation_types/Make_Primer_Aliquot' + '.md',
              type: "local-md"
            },
          
            {
              name: 'Order Primer',
              path: 'operation_types/Order_Primer' + '.md',
              type: "local-md"
            },
          
            {
              name: 'Rehydrate Primer',
              path: 'operation_types/Rehydrate_Primer' + '.md',
              type: "local-md"
            },
          

        ]

      },

    

    

      {

        category: "Libraries",

        contents: [

          
            {
              name: 'AbstractSample',
              path: 'libraries/AbstractSample' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'Feedback',
              path: 'libraries/Feedback' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'Primer',
              path: 'libraries/Primer' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'Units',
              path: 'libraries/Units' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'Vendor',
              path: 'libraries/Vendor' + '.html',
              type: "local-webpage"
            },
          

        ]

    },

    

    
      { category: "Sample Types",
        contents: [
          
            {
              name: 'Primer',
              path: 'sample_types/Primer'  + '.md',
              type: "local-md"
            },
          
        ]
      },
      { category: "Containers",
        contents: [
          
            {
              name: 'Lyophilized Primer',
              path: 'object_types/Lyophilized_Primer'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'Primer Aliquot',
              path: 'object_types/Primer_Aliquot'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'Primer Stock',
              path: 'object_types/Primer_Stock'  + '.md',
              type: "local-md"
            },
          
        ]
      }
    

  ]

};
